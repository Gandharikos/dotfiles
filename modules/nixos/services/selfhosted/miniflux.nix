{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted.services.miniflux;
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.miniflux = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "miniflux";
    defaultPort = 8082;
  };

  config = mkIf cfg.enable {
    services.postgresql.authentication = ''
      host miniflux miniflux 127.0.0.1/32 trust
    '';

    services.miniflux = {
      enable = true;
      config = {
        BASE_URL = "http://${cfg.hostName}/";
        CREATE_ADMIN = 0;
        DATABASE_URL = "postgresql://miniflux@127.0.0.1/miniflux?sslmode=disable";
        LISTEN_ADDR = "${cfg.host}:${toString cfg.port}";
        WATCHDOG = 0;
      };
    };

    systemd.services.miniflux.serviceConfig = {
      Type = lib.mkForce "simple";
      WatchdogSec = lib.mkForce 0;
    };
  };
}
