let
  flake = builtins.getFlake (toString ../..);
  host = flake.nixosConfigurations.athena;
  inherit (host) pkgs;
  inherit (flake.inputs.nixpkgs) lib;
  cfg = host.config;
  withoutAuditd = host.extendModules {
    modules = [ { security.auditd.enable = lib.mkForce false; } ];
  };
  withoutRotation = host.extendModules {
    modules = [ { dot.security.auditd.autoPrune.enable = lib.mkForce false; } ];
  };
in
assert cfg.security.auditd.settings.max_log_file == 64;
assert cfg.security.auditd.settings.num_logs == 8;
assert cfg.security.auditd.settings.max_log_file_action == "rotate";
assert lib.hasInfix "--signal rotate" cfg.systemd.services.clean-audit-log.script;
assert !(lib.hasInfix "rm " cfg.systemd.services.clean-audit-log.script);
assert !(withoutAuditd.config.systemd.timers ? clean-audit-log);
assert !(withoutRotation.config.systemd.timers ? clean-audit-log);
assert cfg.systemd.services.calibre-web.environment.TMPDIR == "/var/lib/calibre-web-upload";
assert cfg.systemd.services.calibre-web.serviceConfig.StateDirectoryMode == "0700";
assert cfg.systemd.services.calibre-web.serviceConfig.PrivateTmp;
assert
  cfg.services.restic.backups.selfhosted.repository
  == "/var/lib/selfhosted-backup/storage/restic/selfhosted";
assert
  cfg.systemd.services.restic-backups-selfhosted.environment.RESTIC_CACHE_DIR
  == "/var/lib/selfhosted-backup/cache";
assert
  cfg.systemd.services.restic-backups-selfhosted.environment.TMPDIR
  == "/var/lib/selfhosted-backup/tmp";
assert
  cfg.dot.selfhosted.backups.health.diskPaths == [
    "/"
    "/nix"
    "/var/lib"
  ];
assert cfg.services.gatus.settings.alerting.custom.url == cfg.dot.selfhosted.backups.alert.ntfyUrl;
pkgs.runCommand "test-storage-configuration" { } ''
  touch "$out"
''
