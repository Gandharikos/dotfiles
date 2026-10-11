{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types)
    bool
    int
    listOf
    port
    str
    ;

  selfhostedExport = lib.dot.mkSelfhostedExportPackage pkgs;
  selfhostedTaildrop = lib.dot.mkSelfhostedTaildropPackage pkgs config;
  backupHealthScript = pkgs.writeText "selfhosted-backup-health.py" (
    builtins.readFile ./backup-health.py
  );
  backupMarkSuccess = pkgs.writeShellApplication {
    name = "selfhosted-backup-mark-success";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      install -d -m 0700 /var/lib/selfhosted-backup
      date +%s > /var/lib/selfhosted-backup/last-success
      printf '%s\n' "''${1:-unknown}" > /var/lib/selfhosted-backup/last-method
    '';
  };
  backupAlert = pkgs.writeShellApplication {
    name = "selfhosted-backup-alert";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.systemd
    ];
    text = ''
      unit="''${1:-unknown}"
      message="$(systemctl status "$unit" --no-pager --lines=40 || true)"
      curl -fsS \
        -H "Title: Selfhosted backup failed" \
        -H "Priority: urgent" \
        -H "Tags: warning" \
        --data-binary "$message" \
        "${cfg.backups.alert.ntfyUrl}" >/dev/null
    '';
  };
in
{
  options.dot.selfhosted.backups = {
    paths = mkOption {
      type = listOf str;
      default = [ ];
      description = "Filesystem paths contributed by self-hosted services for backups.";
    };

    exportDir = mkOption {
      type = str;
      default = "/var/backup/selfhosted";
      description = "Directory where selfhosted-export writes migration archives.";
    };

    schedule = mkOption {
      type = str;
      default = "daily";
      description = "systemd calendar schedule for self-hosted backups.";
    };

    postgresqlDumpFile = mkOption {
      type = str;
      default = "/var/backup/postgresql/all.sql.zst";
      description = "Compressed pg_dumpall output used for backups and restore drills.";
    };

    extraPaths = mkOption {
      type = listOf str;
      default = [ ];
      description = "Additional filesystem paths included in self-hosted backups.";
    };

    alert.ntfyUrl = mkOption {
      type = str;
      default = "http://${cfg.services.ntfy.host}:${toString cfg.services.ntfy.port}/selfhosted-backups";
      description = "ntfy publish URL used for self-hosted backup failure alerts.";
    };

    health = {
      enable = mkOption {
        type = bool;
        default = cfg.services.gatus.enable;
        description = "Whether to expose a local backup health endpoint for Gatus.";
      };

      port = mkOption {
        type = port;
        default = 9191;
        description = "Local port for the self-hosted backup health endpoint.";
      };

      maxAgeHours = mkOption {
        type = int;
        default = 48;
        description = "Maximum age in hours for the last successful backup.";
      };

      diskUsageWarningPercent = mkOption {
        type = lib.types.ints.between 1 100;
        default = 85;
        description = "Filesystem block or inode usage percentage that makes backup health fail.";
      };

      diskPaths = mkOption {
        type = listOf str;
        default = [ "/" ];
        description = "Paths whose filesystems are checked for available space and inodes. The root filesystem is always checked.";
      };
    };

    taildrop = {
      enable = mkOption {
        type = bool;
        default = false;
        description = "Whether successful self-hosted backups are sent to another tailnet device with Tailscale Taildrop.";
      };

      target = mkOption {
        type = str;
        default = "ymir";
        description = "Tailscale Taildrop target device name.";
      };
    };

    restic = {
      repository = mkOption {
        type = str;
        default = "/var/backup/restic/selfhosted";
        description = "Restic repository used for self-hosted backups.";
      };

      pruneOpts = mkOption {
        type = listOf str;
        default = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 6"
        ];
        description = "Restic forget/prune retention options.";
      };
    };

    borg = {
      repository = mkOption {
        type = str;
        default = "/var/backup/borg/selfhosted";
        description = "Borg repository used for self-hosted backups.";
      };

      pruneKeep = mkOption {
        type = lib.types.attrsOf (lib.types.either lib.types.int str);
        default = {
          daily = 7;
          weekly = 4;
          monthly = 6;
        };
        description = "Borg prune retention policy.";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      backupMarkSuccess
      selfhostedExport
      selfhostedTaildrop
    ];

    dot.selfhosted.backups.paths = [
      cfg.backups.exportDir
      (builtins.dirOf cfg.backups.postgresqlDumpFile)
    ]
    ++ cfg.backups.extraPaths;

    systemd.tmpfiles.settings.selfhosted-backup = {
      ${cfg.backups.exportDir}.d = {
        user = "root";
        group = "root";
        mode = "0700";
      };
      "/var/lib/selfhosted-backup".d = {
        user = "root";
        group = "root";
        mode = "0700";
      };
      ${builtins.dirOf cfg.backups.postgresqlDumpFile}.d = {
        user = "root";
        group = "root";
        mode = "0700";
      };
    };

    systemd.services.selfhosted-backup-health = mkIf cfg.backups.health.enable {
      description = "Self-hosted backup health endpoint";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe' pkgs.python3 "python3"} ${backupHealthScript}";
        Restart = "always";
        RestartSec = "10s";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadOnlyPaths = [
          "/var/lib/selfhosted-backup"
          (builtins.dirOf cfg.backups.postgresqlDumpFile)
        ];
      };
      environment = {
        SELFHOSTED_BACKUP_LAST_SUCCESS = "/var/lib/selfhosted-backup/last-success";
        SELFHOSTED_BACKUP_PG_DUMP = cfg.backups.postgresqlDumpFile;
        SELFHOSTED_BACKUP_MAX_AGE_SECONDS = toString (cfg.backups.health.maxAgeHours * 3600);
        SELFHOSTED_BACKUP_DISK_WARN_PERCENT = toString cfg.backups.health.diskUsageWarningPercent;
        SELFHOSTED_BACKUP_DISK_PATHS = builtins.toJSON cfg.backups.health.diskPaths;
        SELFHOSTED_BACKUP_PORT = toString cfg.backups.health.port;
      };
    };

    systemd.services."selfhosted-backup-alert@" = mkIf cfg.services.ntfy.enable {
      description = "Send self-hosted backup failure alert for %i";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe' backupAlert "selfhosted-backup-alert"} %i";
      };
    };
  };
}
