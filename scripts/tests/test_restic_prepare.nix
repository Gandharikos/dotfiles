let
  flake = builtins.getFlake (toString ../..);
  host = flake.nixosConfigurations.athena;
  inherit (host) pkgs;
  lib = flake.inputs.nixpkgs.lib.extend (
    final: _: {
      dot = import ../../lib { lib = final; };
    }
  );
  cfg = host.config.dot.selfhosted.backups;
  exportPackage = lib.dot.mkSelfhostedExportPackage pkgs;
  fakeRunuser = pkgs.writeShellScript "fake-runuser" ''
    [[ "$1" == -u && "$2" == postgres && "$3" == -- ]] || exit 99
    shift 3
    exec "$@"
  '';
  fakeDump = pkgs.writeShellScript "fake-pg-dumpall" ''
    printf 'fixture SQL\n'
    exit "''${DUMP_EXIT:-0}"
  '';
  fakeZstd = pkgs.writeShellScript "fake-zstd" ''
    if [[ "''${ZSTD_FAIL:-0}" == 1 ]]; then exit 9; fi
    if [[ "''${CORRUPT:-0}" == 1 && " $* " == *" -c "* ]]; then
      ${pkgs.coreutils}/bin/cat >/dev/null
      printf 'invalid compressed data\n'
      exit 0
    fi
    exec ${lib.getExe' pkgs.zstd "zstd"} "$@"
  '';
  fakeExport = pkgs.writeShellScript "fake-selfhosted-export" ''
    [[ "$1" == "$work/export/selfhosted-latest.tar.zst" ]] || exit 99
    touch "$EXPORT_MARKER"
  '';
  prepare = pkgs.writeShellScript "test-restic-prepare" (
    builtins.replaceStrings
      [
        (lib.getExe' pkgs.util-linux "runuser")
        (lib.getExe' host.config.services.postgresql.package "pg_dumpall")
        (lib.getExe' pkgs.zstd "zstd")
        (lib.getExe' exportPackage "selfhosted-export")
        (lib.escapeShellArg cfg.exportDir)
        (lib.escapeShellArg (builtins.dirOf cfg.postgresqlDumpFile))
        (lib.escapeShellArg (builtins.dirOf cfg.restic.repository))
        (lib.escapeShellArg cfg.postgresqlDumpFile)
        (lib.escapeShellArg "${cfg.exportDir}/selfhosted-latest.tar.zst")
      ]
      [
        "${fakeRunuser}"
        "${fakeDump}"
        "${fakeZstd}"
        "${fakeExport}"
        ''"$work/export"''
        ''"$work/database"''
        ''"$work/repository"''
        ''"$work/database/all.sql.zst"''
        ''"$work/export/selfhosted-latest.tar.zst"''
      ]
      host.config.services.restic.backups.selfhosted.backupPrepareCommand
  );
in
pkgs.runCommand "test-restic-prepare"
  {
    nativeBuildInputs = [
      pkgs.zstd
      pkgs.python3
      pkgs.gnutar
    ];
  }
  ''
    export work="$TMPDIR/backup staging"
    export EXPORT_MARKER="$work/export-ran"
    mkdir -p "$work/database"
    printf 'known-good\n' > "$work/database/all.sql.zst"
    printf 'stale temporary export\n' > "$work/database/all.sql.zst.tmp"

    assert_preserved() {
      grep -qx 'known-good' "$work/database/all.sql.zst"
      test ! -e "$EXPORT_MARKER"
      test "$(find "$work/database" -name 'all.sql.zst.*' ! -name '*.tmp' | wc -l)" -eq 0
    }
    if DUMP_EXIT=7 ${prepare}; then echo 'Partial dump failure was ignored'; exit 1; fi
    assert_preserved
    if ZSTD_FAIL=1 ${prepare}; then echo 'Compression failure was ignored'; exit 1; fi
    assert_preserved
    if CORRUPT=1 ${prepare}; then echo 'Corrupt archive was accepted'; exit 1; fi
    assert_preserved

    ${prepare}
    zstd -dc "$work/database/all.sql.zst" | grep -qx 'fixture SQL'
    test -e "$EXPORT_MARKER"
    grep -qx 'stale temporary export' "$work/database/all.sql.zst.tmp"
    test "$(find "$work/database" -name 'all.sql.zst.*' ! -name '*.tmp' | wc -l)" -eq 0
    mkdir -p "$work/state/calibre-web"
    printf 'fixture book\n' > "$work/state/calibre-web/example.epub"
    python3 - ${exportPackage}/bin/selfhosted-export "$work/mock-export" <<'PY'
    import os, sys
    from pathlib import Path
    text = Path(sys.argv[1]).read_text()
    replacements = {
        '$(id -u)': '0',
        'systemctl is-active --quiet postgresql.service': 'false',
        '"/var/lib/$directory"': '"$work/state/$directory"',
        'tar -C /var/lib': 'tar -C "$work/state"',
    }
    for old, new in replacements.items():
        assert text.count(old) == 1, old
        text = text.replace(old, new)
    command = 'tar -C "$workdir" --zstd -cpf "$output_tmp" .'
    assert text.count(command) == 1
    text = text.replace(command,
        'if [ "$FAIL_FINAL_TAR" = 1 ]; then printf partial > "$output_tmp"; exit 9; fi\n' + command)
    Path(sys.argv[2]).write_text(text)
    os.chmod(sys.argv[2], 0o700)
    PY
    export FAIL_FINAL_TAR=0
    "$work/mock-export" "$work/export with spaces.tar.zst"
    tar --zstd -xOf "$work/export with spaces.tar.zst" ./var/lib/calibre-web.tar \
      | tar -tf - | grep -qx 'calibre-web/example.epub'
    cp "$work/export with spaces.tar.zst" "$work/last-good-export"
    if FAIL_FINAL_TAR=1 "$work/mock-export" "$work/export with spaces.tar.zst"; then
      echo 'Failed archive export was accepted'; exit 1
    fi
    cmp "$work/last-good-export" "$work/export with spaces.tar.zst"
    test "$(find "$work" -maxdepth 1 -name 'export with spaces.tar.zst.*' | wc -l)" -eq 0
    touch "$out"
  ''
