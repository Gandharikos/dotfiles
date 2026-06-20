{
  config,
  lib,
  pkgs,
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

  package =
    pkgs.runCommand "linkwarden-kanidm-patched-${pkgs.linkwarden.version}"
      { meta = pkgs.linkwarden.meta; }
      ''
        cp -a --reflink=auto ${pkgs.linkwarden}/. $out/
        chmod -R u+w $out

        authFile="$out/share/linkwarden/apps/web/.next/server/pages/api/v1/auth/[...nextauth].js"
        substituteInPlace "$authFile" \
          --replace-fail '"not-before-policy":' 'issued_token_type:__issued_token_type,"not-before-policy":'
      '';
in
{
  options.dot.selfhosted.services.linkwarden = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "linkwarden";
    subdomain = "link";
    defaultPort = 3004;
  };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.linkwarden = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "linkwarden" cfg) ];
      backups.paths = [ "/var/lib/linkwarden" ];
    };

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

    services.kanidm.provision = mkIf oidcEnabled {
      groups.linkwarden-users.members = [ "johnson" ];
      persons.johnson.groups = [ "linkwarden-users" ];
      systems.oauth2.linkwarden = {
        displayName = "Linkwarden";
        originLanding = "https://${cfg.hostName}/";
        originUrl = "https://${cfg.hostName}/api/v1/auth/callback/authentik";
        basicSecretFile = config.sops.secrets.kanidm-oauth2-linkwarden.path;
        preferShortUsername = true;
        enableLegacyCrypto = true;
        scopeMaps.linkwarden-users = [
          "openid"
          "email"
          "profile"
        ];
      };
    };

    services.linkwarden = {
      enable = true;
      inherit package;
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
