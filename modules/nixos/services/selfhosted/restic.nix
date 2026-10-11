{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.dot.selfhosted;
  restic = cfg.backups.restic;
  secretsFile = "${self}/secrets/services/restic.yaml";
  exportPackage = lib.dot.mkSelfhostedExportPackage pkgs;
  taildropPackage = lib.dot.mkSelfhostedTaildropPackage pkgs config;
  backupPathsFile = pkgs.writeText "selfhosted-backup-paths" (lib.concatLines cfg.backups.paths);
  markSuccessPackage = pkgs.writeShellApplication {
    name = "selfhosted-restic-mark-success";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      install -d -m 0700 /var/lib/selfhosted-backup
      date +%s > /var/lib/selfhosted-backup/last-success
      printf 'restic\n' > /var/lib/selfhosted-backup/last-method
    '';
  };
  inherit (lib.modules) mkIf;
in
{
  config = mkIf (cfg.enable && cfg.backup == "restic") {
    environment.systemPackages = [ pkgs.restic ];

    sops.secrets.restic-password = {
      sopsFile = secretsFile;
      key = "password";
      mode = "0400";
    };

    services.restic.backups.selfhosted = {
      inherit (restic) repository;
      passwordFile = config.sops.secrets.restic-password.path;
      initialize = true;
      paths = [ ];
      dynamicFilesFrom = ''
        while IFS= read -r path; do
          [ -e "$path" ] && printf '%s\n' "$path"
        done < ${backupPathsFile}
      '';
      timerConfig = {
        OnCalendar = cfg.backups.schedule;
        RandomizedDelaySec = "30m";
        Persistent = true;
      };
      inherit (restic) pruneOpts;
      backupPrepareCommand = ''
        set -eo pipefail
        install -d -m 0700 ${lib.escapeShellArg cfg.backups.exportDir} \
          ${lib.escapeShellArg (builtins.dirOf cfg.backups.postgresqlDumpFile)} \
          ${lib.optionalString (lib.hasPrefix "/" restic.repository) (
            lib.escapeShellArg (builtins.dirOf restic.repository)
          )}
        dump_file=${lib.escapeShellArg cfg.backups.postgresqlDumpFile}
        dump_tmp=$(mktemp "''${dump_file}.XXXXXX")
        trap 'rm -f -- "$dump_tmp"' EXIT
        ${lib.getExe' pkgs.util-linux "runuser"} -u postgres -- ${lib.getExe' config.services.postgresql.package "pg_dumpall"} \
          | ${lib.getExe' pkgs.zstd "zstd"} -T0 -19 -c > "$dump_tmp"
        ${lib.getExe' pkgs.zstd "zstd"} -q -t "$dump_tmp"
        mv -- "$dump_tmp" "$dump_file"
        trap - EXIT
        ${lib.getExe' exportPackage "selfhosted-export"} ${lib.escapeShellArg "${cfg.backups.exportDir}/selfhosted-latest.tar.zst"}
      '';
    };

    systemd.services.restic-backups-selfhosted = {
      unitConfig.RequiresMountsFor = [
        cfg.backups.exportDir
        (builtins.dirOf cfg.backups.postgresqlDumpFile)
      ]
      ++ lib.optional (lib.hasPrefix "/" restic.repository) restic.repository;
      environment = {
        RESTIC_CACHE_DIR = lib.mkForce "/var/lib/selfhosted-backup/cache";
        TMPDIR = "/var/lib/selfhosted-backup/tmp";
      };
      serviceConfig.StateDirectory = [
        "selfhosted-backup/cache"
        "selfhosted-backup/tmp"
      ];
      serviceConfig.StateDirectoryMode = "0700";
      onFailure = mkIf cfg.services.ntfy.enable [ "selfhosted-backup-alert@%n.service" ];
      serviceConfig.ExecStartPost = [
        "${lib.getExe' markSuccessPackage "selfhosted-restic-mark-success"}"
      ]
      ++ lib.optional cfg.backups.taildrop.enable "${lib.getExe' taildropPackage "selfhosted-taildrop-backup"}";
    };
  };
}
