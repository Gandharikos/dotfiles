{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.rsshub;
  inherit (cfg) redis;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkPackageOption;
  inherit (lib.types)
    attrsOf
    bool
    nullOr
    path
    port
    str
    ;
in
{
  options.dot.selfhosted.services.rsshub =
    lib.dot.mkSelfhostedServiceOptions {
      inherit config;
      name = "rsshub";
      defaultPort = 1200;
      defaultEnable = false;
    }
    // {
      package = mkPackageOption pkgs "rsshub" { };

      cache = {
        enable = mkOption {
          type = bool;
          default = config.dot.selfhosted.services.redis.enable;
          description = "Whether RSSHub should use Redis-compatible cache.";
        };

        expire = mkOption {
          type = str;
          default = "1800";
          description = "RSSHub route cache expiry in seconds.";
        };

        contentExpire = mkOption {
          type = str;
          default = "7200";
          description = "RSSHub content cache expiry in seconds.";
        };
      };

      redis = {
        host = mkOption {
          type = str;
          default = "127.0.0.1";
          description = "Redis-compatible cache host for RSSHub.";
        };

        port = mkOption {
          type = port;
          default = 6372;
          description = "Redis-compatible cache port for RSSHub.";
        };
      };

      extraEnvironment = mkOption {
        type = attrsOf str;
        default = { };
        description = "Additional RSSHub environment variables.";
      };

      environmentFile = mkOption {
        type = nullOr path;
        default = null;
        description = "Environment file containing RSSHub secrets such as ACCESS_KEY.";
      };
    };

  config = mkIf cfg.enable {
    systemd.services.rsshub = {
      description = "RSSHub";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "redis-rsshub.service"
      ];
      wants = [ "network-online.target" ];
      requires = mkIf cfg.cache.enable [ "redis-rsshub.service" ];
      environment = {
        NODE_ENV = "production";
        NO_LOGFILES = "true";
        PORT = toString cfg.port;
        CACHE_TYPE = if cfg.cache.enable then "redis" else "memory";
        CACHE_EXPIRE = cfg.cache.expire;
        CACHE_CONTENT_EXPIRE = cfg.cache.contentExpire;
      }
      // lib.optionalAttrs cfg.cache.enable {
        REDIS_URL = "redis://${redis.host}:${toString redis.port}/";
      }
      // cfg.extraEnvironment;
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/rsshub";
        EnvironmentFile = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
        DynamicUser = true;
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
      };
    };
  };
}
