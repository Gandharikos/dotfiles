{
  config,
  lib,
  self,
  ...
}:
let
  cfg = config.dot.selfhosted.services.linkwarden;
  kanidm = config.dot.selfhosted.services.kanidm;
  oidcEnabled = kanidm.enable;
  secretsFile = "${self}/secrets/services/linkwarden.yaml";
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.linkwarden = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "linkwarden";
    subdomain = "link";
    defaultPort = 3004;
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      linkwarden-nextauth-secret = {
        sopsFile = secretsFile;
        key = "nextauth-secret";
      };
    }
    // optionalAttrs oidcEnabled {
      kanidm-oauth2-linkwarden = {
        sopsFile = secretsFile;
        key = "oauth2-secret";
        owner = "kanidm";
        group = "kanidm";
      };
    };

    sops.templates.linkwarden-env = {
      owner = "root";
      group = "root";
      mode = "0400";
      content = ''
        NEXTAUTH_SECRET=${config.sops.placeholder.linkwarden-nextauth-secret}
        ${lib.optionalString oidcEnabled "AUTHENTIK_CLIENT_SECRET=${config.sops.placeholder.kanidm-oauth2-linkwarden}"}
      '';
      restartUnits = [
        "linkwarden.service"
        "linkwarden-worker.service"
      ];
    };

    services.linkwarden = {
      enable = true;
      inherit (cfg) host port;
      enableRegistration = false;
      environment = {
        NEXTAUTH_URL = "https://${cfg.hostName}/api/v1/auth";
      }
      // optionalAttrs oidcEnabled {
        NEXT_PUBLIC_AUTHENTIK_ENABLED = "true";
        AUTHENTIK_CUSTOM_NAME = "Kanidm";
        AUTHENTIK_ISSUER = "https://${kanidm.hostName}/oauth2/openid/linkwarden";
        AUTHENTIK_CLIENT_ID = "linkwarden";
      };
      environmentFile = config.sops.templates.linkwarden-env.path;
      database.createLocally = true;
    };

    systemd.services = {
      linkwarden = {
        after = [ "postgresql.service" ];
        requires = [ "postgresql.service" ];
      };
      linkwarden-worker = {
        after = [
          "postgresql.service"
          "linkwarden.service"
        ];
        requires = [
          "postgresql.service"
          "linkwarden.service"
        ];
      };
    };
  };
}
