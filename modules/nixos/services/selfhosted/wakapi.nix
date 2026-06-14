{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted.services.wakapi;
  kanidm = config.dot.selfhosted.services.kanidm;
  oidcEnabled = kanidm.enable;
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.wakapi = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "wakapi";
    subdomain = "waka";
    defaultPort = 3003;
  };

  config = mkIf cfg.enable {
    services.wakapi = {
      enable = true;
      database.createLocally = true;
      environmentFiles = mkIf oidcEnabled [ config.sops.templates.wakapi-kanidm-env.path ];
      settings = {
        server = {
          listen_ipv4 = cfg.host;
          inherit (cfg) port;
          public_url = "https://${cfg.hostName}";
        };
        db = {
          dialect = "postgres";
          host = "127.0.0.1";
          name = "wakapi";
          password = "";
          port = 5432;
          user = "wakapi";
        };
        security = {
          allow_signup = false;
          oidc_allow_signup = oidcEnabled;
          oidc = mkIf oidcEnabled [
            {
              name = "kanidm";
              display_name = "Kanidm";
              client_id = "wakapi";
              endpoint = "https://${kanidm.hostName}/oauth2/openid/wakapi";
            }
          ];
        };
      };
    };

    sops.templates.wakapi-kanidm-env = mkIf oidcEnabled {
      owner = "root";
      group = "root";
      mode = "0400";
      content = ''
        WAKAPI_OIDC_PROVIDERS_0_CLIENT_SECRET=${config.sops.placeholder.kanidm-oauth2-wakapi}
      '';
      restartUnits = [ "wakapi.service" ];
    };
  };
}
