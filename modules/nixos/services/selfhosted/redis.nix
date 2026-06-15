{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted;
  redis = cfg.services.redis;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
in
{
  options.dot.selfhosted.services.redis.enable =
    mkEnableOption "Redis-compatible cache for self-hosted services"
    // {
      default = cfg.enable && cfg.services.rsshub.enable;
    };

  config = mkIf redis.enable {
    services.redis.servers = mkIf cfg.services.rsshub.enable {
      rsshub = {
        enable = true;
        bind = cfg.services.rsshub.redis.host;
        port = cfg.services.rsshub.redis.port;
        databases = 16;
        logLevel = "notice";
        appendOnly = false;
        save = [ ];
      };
    };
  };
}
