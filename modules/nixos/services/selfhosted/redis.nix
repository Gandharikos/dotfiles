{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted;
  forgejo = cfg.services.forgejo;
  redis = cfg.services.redis;
  forgejoRedisUrl = "redis://${redis.host}:${toString forgejo.redis.port}/0";
  inherit (lib.modules) mkForce mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) str;
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

  };

  config = mkIf cfg.services.redis.enable {
    services.redis.servers = {
      forgejo = mkIf (forgejo.enable && forgejo.redis.enable) {
        enable = true;
        bind = redis.host;
        port = forgejo.redis.port;
        databases = 16;
        logLevel = "notice";
        save = [ ];
        settings.dbfilename = mkForce "forgejo-cache.rdb";
      };
    };

    dot.selfhosted.services.forgejo.redisUrl = mkIf (
      forgejo.enable && forgejo.redis.enable
    ) forgejoRedisUrl;
  };
}
