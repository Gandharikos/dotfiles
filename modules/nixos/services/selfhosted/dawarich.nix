{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.dawarich;
  kanidm = config.dot.selfhosted.services.kanidm;
  oidcEnabled = kanidm.enable;
  oauth2SecretDir = "/var/lib/kanidm/oauth2/dawarich";
  oauth2ClientSecretFile = "${oauth2SecretDir}/client-secret";
  oauth2EnvFile = "${oauth2SecretDir}/env";
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.dawarich = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "dawarich";
    displayName = "Dawarich";
    subdomain = "pos";
    defaultPort = 5007;
    defaultEnable = false;
  };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.dawarich = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "dawarich" cfg) ];
      backups.paths = [ "/var/lib/dawarich" ];
    };

    services.kanidm.provision = mkIf oidcEnabled {
      groups.dawarich-users.members = [ config.dot.primaryUser ];
      persons.${config.dot.primaryUser}.groups = [ "dawarich-users" ];
      systems.oauth2.dawarich = {
        displayName = "Dawarich";
        originLanding = "https://${cfg.hostName}/users/sign_in";
        originUrl = "https://${cfg.hostName}/users/auth/openid_connect/callback";
        basicSecretFile = oauth2ClientSecretFile;
        preferShortUsername = true;
        scopeMaps.dawarich-users = [
          "openid"
          "email"
          "profile"
        ];
      };
    };

    services.dawarich = {
      enable = true;
      configureNginx = false;
      localDomain = cfg.hostName;
      webPort = cfg.port;
      environment = {
        APPLICATION_PROTOCOL = if config.dot.selfhosted.useHttps then "https" else "http";
        APPLICATION_HOSTS = "127.0.0.1,::1,${cfg.hostName}";
      }
      // lib.optionalAttrs oidcEnabled {
        ALLOW_EMAIL_PASSWORD_LOGIN = "false";
        ALLOW_EMAIL_PASSWORD_REGISTRATION = "false";
        OIDC_AUTO_REGISTER = "true";
        OIDC_CLIENT_ID = "dawarich";
        OIDC_ISSUER = "https://${kanidm.hostName}/oauth2/openid/dawarich";
        OIDC_PKCE_ENABLED = "true";
        OIDC_PROVIDER_NAME = "Kanidm";
        OIDC_REDIRECT_URI = "https://${cfg.hostName}/users/auth/openid_connect/callback";
      };
      extraEnvFiles = lib.optional oidcEnabled oauth2EnvFile;
      database.createLocally = true;
      redis.createLocally = true;
    };

    systemd = {
      services = {
        kanidm = mkIf oidcEnabled {
          after = [ "dawarich-oauth2-secrets.service" ];
          requires = [ "dawarich-oauth2-secrets.service" ];
        };

        dawarich-oauth2-secrets = mkIf oidcEnabled {
          description = "Generate Dawarich OAuth2 secrets";
          before = [
            "kanidm.service"
            "dawarich.target"
            "dawarich-init-db.service"
            "dawarich-web.service"
          ];
          requiredBy = [
            "kanidm.service"
            "dawarich.target"
          ];
          serviceConfig.Type = "oneshot";
          script = ''
            ${pkgs.coreutils}/bin/install -d -m 0750 -o root -g kanidm ${oauth2SecretDir}

            if [ ! -s ${oauth2ClientSecretFile} ]; then
              ${pkgs.openssl}/bin/openssl rand -base64 48 | ${pkgs.coreutils}/bin/tr -d '\n' > ${oauth2ClientSecretFile}
            fi

            ${pkgs.coreutils}/bin/chown root:kanidm ${oauth2ClientSecretFile}
            ${pkgs.coreutils}/bin/chmod 0440 ${oauth2ClientSecretFile}

            {
              printf 'OIDC_CLIENT_SECRET=%s\n' "$(${pkgs.coreutils}/bin/cat ${oauth2ClientSecretFile})"
            } > ${oauth2EnvFile}

            ${pkgs.coreutils}/bin/chown root:root ${oauth2EnvFile}
            ${pkgs.coreutils}/bin/chmod 0400 ${oauth2EnvFile}
          '';
        };

        dawarich-init-db = mkIf oidcEnabled {
          after = [ "dawarich-oauth2-secrets.service" ];
          requires = [ "dawarich-oauth2-secrets.service" ];
        };

        dawarich-web = mkIf oidcEnabled {
          after = [ "dawarich-oauth2-secrets.service" ];
          requires = [ "dawarich-oauth2-secrets.service" ];
        };
      };

      targets.dawarich = mkIf oidcEnabled {
        after = [ "dawarich-oauth2-secrets.service" ];
        requires = [ "dawarich-oauth2-secrets.service" ];
      };
    };
  };
}
