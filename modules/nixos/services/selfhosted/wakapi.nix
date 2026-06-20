{
  config,
  lib,
  self,
  ...
}:
let
  cfg = config.dot.selfhosted.services.wakapi;
  kanidm = config.dot.selfhosted.services.kanidm;
  oidcEnabled = kanidm.enable;
  secretsFile = "${self}/secrets/services/kanidm.yaml";
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
    dot.selfhosted = {
      proxyBackends.wakapi = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "wakapi" cfg) ];
      backups.paths = [ "/var/lib/wakapi" ];
    };

    sops.secrets.kanidm-oauth2-wakapi = mkIf oidcEnabled {
      sopsFile = secretsFile;
      key = "oauth2-wakapi";
      owner = "kanidm";
      group = "kanidm";
    };

    services.kanidm.provision = mkIf oidcEnabled {
      groups.wakapi-users.members = [ "johnson" ];
      persons.johnson.groups = [ "wakapi-users" ];
      systems.oauth2.wakapi = {
        displayName = "Wakapi";
        originLanding = "https://${cfg.hostName}/oidc/kanidm/login";
        originUrl = "https://${cfg.hostName}/oidc/kanidm/callback";
        basicSecretFile = config.sops.secrets.kanidm-oauth2-wakapi.path;
        allowInsecureClientDisablePkce = true;
        preferShortUsername = true;
        scopeMaps.wakapi-users = [
          "openid"
          "email"
          "profile"
        ];
      };
    };

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
