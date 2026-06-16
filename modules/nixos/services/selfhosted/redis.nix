{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted;
  redis = cfg.services.redis;
  forgejoRedisUrl = "redis://${redis.host}:${toString redis.forgejo.port}/0";
  inherit (lib.modules) mkForce mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) port str;
in
{
  options.dot.selfhosted.services.redis = {
    enable = mkEnableOption "Redis-compatible cache for self-hosted services" // {
      default = cfg.enable;
    };

    host = mkOption {
      type = str;
      default = "127.0.0.1";
      description = "Address Redis-compatible self-hosted services listen on.";
    };

    forgejo.port = mkOption {
      type = port;
      default = 6371;
      description = "Redis-compatible port used by Forgejo.";
    };

    rsshub.port = mkOption {
      type = port;
      default = 6372;
      description = "Redis-compatible port used by RSSHub.";
    };
  };

  config = mkIf cfg.services.redis.enable {
    services.redis.servers = mkIf cfg.services.forgejo.enable {
      forgejo = {
        enable = true;
        bind = redis.host;
        port = redis.forgejo.port;
        databases = 16;
        logLevel = "notice";
        save = [ ];
        settings.dbfilename = mkForce "forgejo-cache.rdb";
      };
    };

    dot.selfhosted.services.forgejo.redisUrl = mkIf cfg.services.forgejo.enable forgejoRedisUrl;
  };
}
