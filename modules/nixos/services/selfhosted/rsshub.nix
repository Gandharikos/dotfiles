{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.rsshub;
  redis = config.dot.selfhosted.services.redis;
  inherit (lib.options) mkOption;
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.types) port;
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
      redis.port = mkOption {
        type = port;
        default = 6372;
        description = "Redis-compatible port used by RSSHub.";
      };
    };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.rsshub = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "rsshub" cfg) ];
    };

    services.rsshub = {
      enable = true;

      redis = {
        inherit (redis) enable;
        createLocally = mkDefault redis.enable;
        inherit (redis) host;
        inherit (cfg.redis) port;
      };

      settings = {
        NODE_ENV = "production";
        PORT = cfg.port;
        LISTEN_INADDR_ANY = false;
        CACHE_EXPIRE = "1800";
        CACHE_CONTENT_EXPIRE = "7200";
        CHROMIUM_EXECUTABLE_PATH = lib.getExe pkgs.chromium;
        PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
      };
    };
  };
}
