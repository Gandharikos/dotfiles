{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted.services.forgejo;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types) bool;
in
{
  options.dot.selfhosted.services.forgejo =
    lib.dot.mkSelfhostedServiceOptions {
      inherit config;
      name = "forgejo";
      defaultPort = 3000;
    }
    // {
      allowRegistration = mkOption {
        type = bool;
        default = false;
        description = "Whether public Forgejo account registration is allowed.";
      };
    };

  config = mkIf cfg.enable {
    services.forgejo = {
      enable = true;
      database.type = "sqlite3";
      settings = {
        server = {
          DISABLE_SSH = true;
          DOMAIN = cfg.hostName;
          HTTP_ADDR = cfg.host;
          HTTP_PORT = cfg.port;
          ROOT_URL = "http://${cfg.hostName}/";
        };
        service.DISABLE_REGISTRATION = !cfg.allowRegistration;
      };
    };
  };
}
