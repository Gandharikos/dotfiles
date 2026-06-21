{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.fava;
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
  oauth2SecretDir = "${cfg.dataDir}/oauth2";
  oauth2ClientSecretFile = "${oauth2SecretDir}/client-secret";
  oauth2CookieSecretFile = "${oauth2SecretDir}/cookie-secret";
  oauth2EnvFile = "${oauth2SecretDir}/env";
  dataDirGroup = if oidcEnabled then "kanidm" else "fava";
  inherit (lib) getExe;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types)
    bool
    package
    port
    str
    ;
in
{
  options.dot.selfhosted.services.fava =
    lib.dot.mkSelfhostedServiceOptions {
      inherit config;
      name = "fava";
      displayName = "Fava";
      subdomain = "budget";
      defaultPort = 5000;
      defaultEnable = false;
    }
    // {
      package = mkOption {
        type = package;
        default = pkgs.fava;
        description = "Fava package to run.";
      };

      dataDir = mkOption {
        type = str;
        default = "/var/lib/fava";
        description = "Fava and Beancount data directory.";
      };

      ledgerFile = mkOption {
        type = str;
        default = "${cfg.dataDir}/main.bean";
        description = "Beancount ledger opened by Fava.";
      };

      readOnly = mkOption {
        type = bool;
        default = true;
        description = "Whether Fava is started in read-only mode.";
      };

      authProxy.port = mkOption {
        type = port;
        default = 4182;
        description = "Local oauth2-proxy port used when Kanidm protects Fava.";
      };
    };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.fava = {
        inherit (cfg)
          hostName
          localHostAlias
          ;
        inherit (proxyBackend) host port scheme;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "fava" cfg) ];
      backups.paths = [ cfg.dataDir ];
    };

    services.kanidm.provision = mkIf oidcEnabled {
      groups.fava-users.members = [ "johnson" ];
      persons.johnson.groups = [ "fava-users" ];
      systems.oauth2.fava = {
        displayName = "Fava";
        originLanding = "https://${cfg.hostName}/";
        originUrl = "https://${cfg.hostName}/oauth2/callback";
        basicSecretFile = oauth2ClientSecretFile;
        preferShortUsername = true;
        scopeMaps.fava-users = [
          "openid"
          "email"
          "profile"
        ];
      };
    };

    users = {
      groups.fava = { };
      users.fava = {
        isSystemUser = true;
        group = "fava";
        home = cfg.dataDir;
        createHome = true;
      };
    };

    systemd.tmpfiles.settings.selfhosted-fava.${cfg.dataDir}.d = {
      user = "fava";
      group = dataDirGroup;
      mode = "0750";
    };

    systemd.services = {
      fava-oauth2-secrets = mkIf oidcEnabled {
        description = "Generate Fava OAuth2 secrets";
        before = [
          "kanidm.service"
          "oauth2-proxy-fava.service"
        ];
        requiredBy = [
          "kanidm.service"
          "oauth2-proxy-fava.service"
        ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          ${pkgs.coreutils}/bin/chgrp kanidm ${cfg.dataDir}
          ${pkgs.coreutils}/bin/chmod 0750 ${cfg.dataDir}
          ${pkgs.coreutils}/bin/install -d -m 0750 -o fava -g kanidm ${oauth2SecretDir}

          if [ ! -s ${oauth2ClientSecretFile} ]; then
            ${pkgs.openssl}/bin/openssl rand -base64 48 > ${oauth2ClientSecretFile}
          fi

          cookie_secret="$(${pkgs.coreutils}/bin/cat ${oauth2CookieSecretFile} 2>/dev/null || true)"
          if [ ''${#cookie_secret} -ne 16 ] && [ ''${#cookie_secret} -ne 24 ] && [ ''${#cookie_secret} -ne 32 ]; then
            ${pkgs.openssl}/bin/openssl rand -hex 16 > ${oauth2CookieSecretFile}
          fi

          ${pkgs.coreutils}/bin/chown fava:kanidm ${oauth2ClientSecretFile} ${oauth2CookieSecretFile}
          ${pkgs.coreutils}/bin/chmod 0440 ${oauth2ClientSecretFile} ${oauth2CookieSecretFile}

          {
            printf 'OAUTH2_PROXY_CLIENT_SECRET=%s\n' "$(${pkgs.coreutils}/bin/cat ${oauth2ClientSecretFile})"
            printf 'OAUTH2_PROXY_COOKIE_SECRET=%s\n' "$(${pkgs.coreutils}/bin/cat ${oauth2CookieSecretFile})"
          } > ${oauth2EnvFile}

          ${pkgs.coreutils}/bin/chown root:root ${oauth2EnvFile}
          ${pkgs.coreutils}/bin/chmod 0400 ${oauth2EnvFile}
        '';
      };

      fava-ledger-init = {
        description = "Initialize Fava Beancount ledger";
        before = [ "fava.service" ];
        requiredBy = [ "fava.service" ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          ${pkgs.coreutils}/bin/install -d -m 0750 -o fava -g ${dataDirGroup} ${cfg.dataDir}
          if [ ! -s ${cfg.ledgerFile} ]; then
            ${pkgs.coreutils}/bin/cat > ${cfg.ledgerFile} <<'EOF'
          option "title" "Johnson Budget"
          option "operating_currency" "USD"

          2026-01-01 open Assets:Cash USD
          2026-01-01 open Equity:Opening-Balances USD
          EOF
            ${pkgs.coreutils}/bin/chown fava:fava ${cfg.ledgerFile}
            ${pkgs.coreutils}/bin/chmod 0640 ${cfg.ledgerFile}
          fi
        '';
      };

      fava = {
        description = "Fava Beancount web UI";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "fava-ledger-init.service"
        ];
        requires = [ "fava-ledger-init.service" ];
        script = ''
          exec ${getExe cfg.package} \
            --host ${cfg.host} \
            --port ${toString cfg.port} \
            ${lib.optionalString cfg.readOnly "--read-only"} \
            ${cfg.ledgerFile}
        '';
        serviceConfig = {
          User = "fava";
          Group = "fava";
          Restart = "always";
          RestartSec = "10s";
          WorkingDirectory = cfg.dataDir;
        };
      };

      oauth2-proxy-fava = mkIf oidcEnabled {
        description = "oauth2-proxy for Fava";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "kanidm.service"
          "fava.service"
          "fava-oauth2-secrets.service"
        ];
        requires = [
          "kanidm.service"
          "fava.service"
          "fava-oauth2-secrets.service"
        ];
        script = ''
          exec ${getExe pkgs.oauth2-proxy} \
            --provider=oidc \
            --oidc-issuer-url=https://${kanidm.hostName}/oauth2/openid/fava \
            --client-id=fava \
            --http-address=http://${cfg.host}:${toString cfg.authProxy.port} \
            --redirect-url=https://${cfg.hostName}/oauth2/callback \
            --upstream=http://${cfg.host}:${toString cfg.port}/ \
            --scope="openid email profile" \
            --email-domain="*" \
            --reverse-proxy=true \
            --cookie-secure=true \
            --cookie-name=_fava_oauth2_proxy \
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
