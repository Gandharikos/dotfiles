{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted;
  inherit (lib.modules) mkIf;
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

    rsshub.port = mkOption {
      type = port;
      default = 6372;
      description = "Redis-compatible port used by RSSHub.";
    };
  };

  config = mkIf cfg.services.redis.enable { };
}
