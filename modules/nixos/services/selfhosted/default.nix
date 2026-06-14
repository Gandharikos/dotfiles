{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted;
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types)
    bool
    enum
    listOf
    str
    ;

  proxyBackends = lib.dot.mkSelfhostedProxyBackends config;
  proxyHostNames = map (service: service.hostName) (attrValues proxyBackends);
  selfhostedExport = lib.dot.mkSelfhostedExportPackage pkgs;
in
{
  imports = lib.dot.scanPaths ./.;

  options.dot.selfhosted = {
    enable = mkEnableOption "self-hosted services" // {
      default = config.dot.device.type == "server";
    };

    domain = mkOption {
      type = str;
      default = "localhost";
      description = "Domain used for self-hosted reverse-proxy host names.";
    };

    useHttps = mkOption {
      type = bool;
      default = cfg.domain != "localhost";
      description = "Whether reverse proxies should serve self-hosted domains over HTTPS.";
    };

    reverseProxy = mkOption {
      type = enum [
        "caddy"
        "nginx"
      ];
      default = "caddy";
      description = "Reverse proxy implementation for self-hosted services.";
    };

    backup = mkOption {
      type = enum [
        "restic"
        "borg"
      ];
      default = "restic";
      description = "Backup tool preference for self-hosted service data.";
    };

    monitoring = mkOption {
      type = enum [
        "uptime-kuma"
        "gatus"
      ];
      default = "gatus";
      description = "Monitoring service to deploy for self-hosted services.";
    };

    backups = {
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

      restic = {
        repository = mkOption {
          type = str;
          default = "/var/backup/restic/selfhosted";
          description = "Restic repository used for self-hosted backups.";
        };

        passwordFile = mkOption {
          type = str;
          default = "/var/lib/selfhosted-backup/restic-password";
          description = "Restic repository password file.";
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
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = [ selfhostedExport ];
      networking.hosts."127.0.0.1" = proxyHostNames;
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
      };
    }
  ]);
}
