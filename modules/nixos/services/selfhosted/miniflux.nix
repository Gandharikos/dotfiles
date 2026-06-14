{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted.services.miniflux;
  kanidm = config.dot.selfhosted.services.kanidm;
  oidcEnabled = kanidm.enable;
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.miniflux = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "miniflux";
    subdomain = "rss";
    defaultPort = 8082;
  };

  config = mkIf cfg.enable {
    services.postgresql.authentication = ''
      host miniflux miniflux 127.0.0.1/32 trust
    '';

    services.miniflux = {
      enable = true;
      config = {
        BASE_URL = "https://${cfg.hostName}/";
        CREATE_ADMIN = 0;
        DATABASE_URL = "postgresql://miniflux@127.0.0.1/miniflux?sslmode=disable";
        LISTEN_ADDR = "${cfg.host}:${toString cfg.port}";
        OAUTH2_CLIENT_ID = mkIf oidcEnabled "miniflux";
        OAUTH2_OIDC_DISCOVERY_ENDPOINT = mkIf oidcEnabled "https://${kanidm.hostName}/oauth2/openid/miniflux";
        OAUTH2_PROVIDER = mkIf oidcEnabled "oidc";
        OAUTH2_REDIRECT_URL = mkIf oidcEnabled "https://${cfg.hostName}/oauth2/oidc/callback";
        OAUTH2_USER_CREATION = mkIf oidcEnabled 1;
        WATCHDOG = 0;
      };
    };

    sops.templates.miniflux-kanidm-env = mkIf oidcEnabled {
      owner = "root";
      group = "root";
      mode = "0400";
      content = ''
        OAUTH2_CLIENT_SECRET=${config.sops.placeholder.kanidm-oauth2-miniflux}
      '';
      restartUnits = [ "miniflux.service" ];
    };

    systemd.services.miniflux.serviceConfig = {
      EnvironmentFile = mkIf oidcEnabled [ config.sops.templates.miniflux-kanidm-env.path ];
      Type = lib.mkForce "simple";
      WatchdogSec = lib.mkForce 0;
    };
  };
}
