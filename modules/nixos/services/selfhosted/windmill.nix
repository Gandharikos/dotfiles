{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.windmill;
  kanidm = config.dot.selfhosted.services.kanidm;
  oidcEnabled = kanidm.enable;
  proxyBackend =
    if oidcEnabled then
      {
        inherit (cfg) host scheme;
        port = cfg.authProxy.port;
      }
    else
      cfg;
  oauth2SecretDir = "/var/lib/kanidm/oauth2/windmill";
  oauth2ClientSecretFile = "${oauth2SecretDir}/client-secret";
  oauth2CookieSecretFile = "${oauth2SecretDir}/cookie-secret";
  oauth2EnvFile = "${oauth2SecretDir}/env";
  inherit (lib) getExe;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types) port;
in
{
  options.dot.selfhosted.services.windmill =
    lib.dot.mkSelfhostedServiceOptions {
      inherit config;
      name = "windmill";
      displayName = "Windmill";
      subdomain = "workflow";
      defaultPort = 8001;
      defaultEnable = false;
    }
    // {
      authProxy.port = mkOption {
        type = port;
        default = 4184;
        description = "Local oauth2-proxy port used when Kanidm protects Windmill.";
      };
    };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.windmill = {
        inherit (cfg)
          hostName
          localHostAlias
          ;
        inherit (proxyBackend) host port scheme;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "windmill" cfg) ];
      backups.paths = [ "/var/lib/windmill" ];
    };

    services.kanidm.provision = mkIf oidcEnabled {
      groups.windmill-users.members = [ config.dot.primaryUser ];
      persons.${config.dot.primaryUser}.groups = [ "windmill-users" ];
      systems.oauth2.windmill = {
        displayName = "Windmill";
        originLanding = "https://${cfg.hostName}/";
        originUrl = "https://${cfg.hostName}/oauth2/callback";
        basicSecretFile = oauth2ClientSecretFile;
        preferShortUsername = true;
        scopeMaps.windmill-users = [
          "openid"
          "email"
          "profile"
        ];
      };
    };

    services.windmill = {
      enable = true;
      serverPort = cfg.port;
      baseUrl = "https://${cfg.hostName}";
      database.createLocally = true;
    };

    systemd.services = {
      kanidm = mkIf oidcEnabled {
        after = [ "windmill-oauth2-secrets.service" ];
        requires = [ "windmill-oauth2-secrets.service" ];
      };

      windmill-oauth2-secrets = mkIf oidcEnabled {
        description = "Generate Windmill OAuth2 secrets";
        before = [
          "kanidm.service"
          "windmill-server.service"
        ];
        requiredBy = [
          "kanidm.service"
          "windmill-server.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ${pkgs.coreutils}/bin/install -d -m 0750 -o root -g kanidm ${oauth2SecretDir}

          if [ ! -s ${oauth2ClientSecretFile} ]; then
            ${pkgs.openssl}/bin/openssl rand -base64 48 | ${pkgs.coreutils}/bin/tr -d '\n' > ${oauth2ClientSecretFile}
          fi

          cookie_secret="$(${pkgs.coreutils}/bin/cat ${oauth2CookieSecretFile} 2>/dev/null || true)"
          if [ ''${#cookie_secret} -ne 16 ] && [ ''${#cookie_secret} -ne 24 ] && [ ''${#cookie_secret} -ne 32 ]; then
            ${pkgs.openssl}/bin/openssl rand -hex 16 > ${oauth2CookieSecretFile}
          fi

          ${pkgs.coreutils}/bin/chown root:kanidm ${oauth2ClientSecretFile} ${oauth2CookieSecretFile}
          ${pkgs.coreutils}/bin/chmod 0440 ${oauth2ClientSecretFile} ${oauth2CookieSecretFile}

          {
            printf 'OAUTH2_PROXY_CLIENT_SECRET=%s\n' "$(${pkgs.coreutils}/bin/cat ${oauth2ClientSecretFile})"
            printf 'OAUTH2_PROXY_COOKIE_SECRET=%s\n' "$(${pkgs.coreutils}/bin/cat ${oauth2CookieSecretFile})"
          } > ${oauth2EnvFile}

          ${pkgs.coreutils}/bin/chown root:root ${oauth2EnvFile}
          ${pkgs.coreutils}/bin/chmod 0400 ${oauth2EnvFile}
        '';
      };

      oauth2-proxy-windmill = mkIf oidcEnabled {
        description = "oauth2-proxy for Windmill";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "kanidm.service"
          "windmill-server.service"
          "windmill-oauth2-secrets.service"
        ];
        requires = [
          "kanidm.service"
          "windmill-server.service"
          "windmill-oauth2-secrets.service"
        ];
        script = ''
          exec ${getExe pkgs.oauth2-proxy} \
            --provider=oidc \
            --oidc-issuer-url=https://${kanidm.hostName}/oauth2/openid/windmill \
            --client-id=windmill \
            --http-address=http://${cfg.host}:${toString cfg.authProxy.port} \
            --redirect-url=https://${cfg.hostName}/oauth2/callback \
            --upstream=http://${cfg.host}:${toString cfg.port}/ \
            --scope="openid email profile" \
            --email-domain="*" \
            --reverse-proxy=true \
            --trusted-proxy-ip=127.0.0.1/32 \
            --trusted-proxy-ip=::1/128 \
            --cookie-secure=true \
            --cookie-name=_windmill_oauth2_proxy \
            --cookie-domain=${cfg.hostName} \
            --pass-basic-auth=true \
            --pass-host-header=true \
            --set-xauthrequest=true \
            --skip-provider-button=true \
            --code-challenge-method=S256 \
            --oidc-email-claim=preferred_username \
            --prefer-email-to-user=true
        '';
        serviceConfig = {
          DynamicUser = true;
          EnvironmentFile = oauth2EnvFile;
          Restart = "always";
          RestartSec = "10s";
        };
      };
    };
  };
}
