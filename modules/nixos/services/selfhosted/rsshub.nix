{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.rsshub;
  redis = config.dot.selfhosted.services.redis;
  inherit (lib.modules) mkDefault mkIf;
in
{
  options.dot.selfhosted.services.rsshub = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "rsshub";
    defaultPort = 1200;
    defaultEnable = false;
  };

  config = mkIf cfg.enable {
    services.rsshub = {
      enable = true;

      redis = {
        enable = mkDefault redis.enable;
        createLocally = mkDefault redis.enable;
        host = mkDefault redis.host;
        port = mkDefault redis.rsshub.port;
      };

      settings = {
        NODE_ENV = mkDefault "production";
        PORT = mkDefault cfg.port;
        LISTEN_INADDR_ANY = mkDefault false;
        CACHE_EXPIRE = mkDefault "1800";
        CACHE_CONTENT_EXPIRE = mkDefault "7200";
        CHROMIUM_EXECUTABLE_PATH = mkDefault (lib.getExe pkgs.chromium);
        PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = mkDefault "true";
      };
    };
  };
}
