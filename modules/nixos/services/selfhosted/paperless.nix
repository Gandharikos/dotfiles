{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.paperless;
  kanidm = config.dot.selfhosted.services.kanidm;
  oidcEnabled = kanidm.enable;
  adminPasswordFile = "${config.services.paperless.dataDir}/admin-password";
  kanidmOauth2SecretDir = "/var/lib/kanidm/oauth2/paperless";
  kanidmOauth2ClientSecretFile = "${kanidmOauth2SecretDir}/client-secret";
  oauth2SecretDir = "${config.services.paperless.dataDir}/oauth2";
  oauth2EnvFile = "${oauth2SecretDir}/env";
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.paperless = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "paperless";
    displayName = "Paperless-ngx";
    subdomain = "paper";
    defaultPort = 28981;
    defaultEnable = false;
  };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.paperless = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "paperless" cfg) ];
      backups.paths = [ config.services.paperless.dataDir ];
    };

    services.kanidm.provision = mkIf oidcEnabled {
      groups.paperless-users.members = [ config.dot.primaryUser ];
      persons.${config.dot.primaryUser}.groups = [ "paperless-users" ];
      systems.oauth2.paperless = {
        displayName = "Paperless-ngx";
        originLanding = "https://${cfg.hostName}/accounts/oidc/kanidm/login/";
        originUrl = "https://${cfg.hostName}/accounts/oidc/kanidm/login/callback/";
        basicSecretFile = kanidmOauth2ClientSecretFile;
        preferShortUsername = true;
        scopeMaps.paperless-users = [
          "openid"
          "email"
          "profile"
        ];
      };
    };

    services.paperless = {
      enable = true;
      address = cfg.host;
      inherit (cfg) port;
      domain = cfg.hostName;
      environmentFile = mkIf oidcEnabled oauth2EnvFile;
      passwordFile = adminPasswordFile;
      database.createLocally = true;
      settings = {
        PAPERLESS_ACCOUNT_ALLOW_SIGNUPS = false;
        PAPERLESS_ACCOUNT_DEFAULT_HTTP_PROTOCOL = "https";
        PAPERLESS_ACCOUNT_EMAIL_VERIFICATION = "none";
        PAPERLESS_ADMIN_USER = config.dot.primaryUser;
        PAPERLESS_APPS = mkIf oidcEnabled "allauth.socialaccount.providers.openid_connect";
        PAPERLESS_DISABLE_REGULAR_LOGIN = oidcEnabled;
        PAPERLESS_REDIRECT_LOGIN_TO_SSO = oidcEnabled;
        PAPERLESS_SOCIALACCOUNT_ALLOW_SIGNUPS = oidcEnabled;
        PAPERLESS_SOCIAL_AUTO_SIGNUP = oidcEnabled;
        PAPERLESS_URL = "https://${cfg.hostName}";
      };
    };

    systemd.tmpfiles.rules = [
      "d ${config.services.paperless.dataDir}/consume 0750 paperless paperless -"
      "d ${config.services.paperless.dataDir}/media 0750 paperless paperless -"
    ];

    systemd.services = {
      kanidm = mkIf oidcEnabled {
        after = [ "paperless-oauth2-secrets.service" ];
        requires = [ "paperless-oauth2-secrets.service" ];
      };

      paperless-oauth2-secrets = mkIf oidcEnabled {
        description = "Generate Paperless OAuth2 secrets";
        before = [
          "kanidm.service"
          "paperless-web.service"
          "paperless-scheduler.service"
          "paperless-consumer.service"
          "paperless-task-queue.service"
        ];
        requiredBy = [
          "kanidm.service"
          "paperless-web.service"
        ];
        serviceConfig.Type = "oneshot";
        script = ''
          ${pkgs.coreutils}/bin/install -d -m 0750 -o root -g kanidm ${kanidmOauth2SecretDir}
          ${pkgs.coreutils}/bin/install -d -m 0750 -o paperless -g paperless ${config.services.paperless.dataDir}
          ${pkgs.coreutils}/bin/chown paperless:paperless ${config.services.paperless.dataDir}
          ${pkgs.coreutils}/bin/chmod 0750 ${config.services.paperless.dataDir}
          ${pkgs.coreutils}/bin/install -d -m 0750 -o paperless -g paperless ${oauth2SecretDir}

          if [ ! -s ${kanidmOauth2ClientSecretFile} ]; then
            ${pkgs.openssl}/bin/openssl rand -base64 48 | ${pkgs.coreutils}/bin/tr -d '\n' > ${kanidmOauth2ClientSecretFile}
          fi

          ${pkgs.coreutils}/bin/chown root:kanidm ${kanidmOauth2ClientSecretFile}
          ${pkgs.coreutils}/bin/chmod 0440 ${kanidmOauth2ClientSecretFile}

          providers="$(${pkgs.jq}/bin/jq -cn \
            --arg secret "$(${pkgs.coreutils}/bin/cat ${kanidmOauth2ClientSecretFile})" \
            --arg serverUrl "https://${kanidm.hostName}/oauth2/openid/paperless" \
            '{
              openid_connect: {
                OAUTH_PKCE_ENABLED: true,
                APPS: [
                  {
                    provider_id: "kanidm",
                    name: "Kanidm",
                    client_id: "paperless",
                    secret: $secret,
                    settings: {
                      fetch_userinfo: true,
                      oauth_pkce_enabled: true,
                      server_url: $serverUrl,
                      token_auth_method: "client_secret_basic",
                      uid_field: "sub"
                    }
                  }
                ]
              }
            }')"

          printf "PAPERLESS_SOCIALACCOUNT_PROVIDERS='%s'\n" "$providers" > ${oauth2EnvFile}
          ${pkgs.coreutils}/bin/chown paperless:paperless ${oauth2EnvFile}
          ${pkgs.coreutils}/bin/chmod 0400 ${oauth2EnvFile}
        '';
      };

      paperless-kanidm-admin = mkIf oidcEnabled {
        description = "Bind Paperless Kanidm account to the primary admin user";
        after = [
          "paperless-web.service"
          "paperless-oauth2-secrets.service"
        ];
        requires = [ "paperless-oauth2-secrets.service" ];
        wants = [ "paperless-web.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = "paperless";
          Group = "paperless";
        };
        script = ''
          ${config.services.paperless.manage}/bin/paperless-manage shell -c '
          from django.contrib.auth import get_user_model
          from allauth.socialaccount.models import SocialAccount

          User = get_user_model()
          admin = User.objects.get(username="${config.dot.primaryUser}")
          admin.email = "${config.dot.admin.email}"
          admin.is_superuser = True
          admin.is_staff = True
          admin.save()

          for account in SocialAccount.objects.filter(provider="kanidm"):
              id_token = account.extra_data.get("id_token", {})
              userinfo = account.extra_data.get("userinfo", {})
              preferred_username = id_token.get("preferred_username") or userinfo.get("preferred_username")
              email = id_token.get("email") or userinfo.get("email")
              if preferred_username == "${config.dot.primaryUser}" or email == "${config.dot.admin.email}":
                  account.user = admin
                  account.save()

          User.objects.filter(
              email="${config.dot.admin.email}",
              is_superuser=False,
          ).exclude(username="${config.dot.primaryUser}").delete()
          '
        '';
      };

      paperless-admin-password = {
        description = "Generate Paperless admin password";
        before = [
          "paperless-web.service"
          "paperless-scheduler.service"
          "paperless-consumer.service"
          "paperless-task-queue.service"
        ];
        requiredBy = [ "paperless-web.service" ];
        serviceConfig.Type = "oneshot";
        script = ''
          ${pkgs.coreutils}/bin/install -d -m 0750 -o paperless -g paperless ${config.services.paperless.dataDir}
          ${pkgs.coreutils}/bin/chown paperless:paperless ${config.services.paperless.dataDir}
          ${pkgs.coreutils}/bin/chmod 0750 ${config.services.paperless.dataDir}
          if [ ! -s ${adminPasswordFile} ]; then
            ${pkgs.openssl}/bin/openssl rand -base64 24 > ${adminPasswordFile}
          fi
          ${pkgs.coreutils}/bin/chown paperless:paperless ${adminPasswordFile}
          ${pkgs.coreutils}/bin/chmod 0400 ${adminPasswordFile}
        '';
      };
    };
  };
}
