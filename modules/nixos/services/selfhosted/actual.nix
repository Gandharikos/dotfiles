{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.actual;
  kanidm = config.dot.selfhosted.services.kanidm;
  oidcEnabled = kanidm.enable;
  kanidmOauth2SecretDir = "/var/lib/kanidm/oauth2/actual";
  kanidmOauth2ClientSecretFile = "${kanidmOauth2SecretDir}/client-secret";
  oauth2SecretDir = "${config.services.actual.settings.dataDir}/oauth2";
  oauth2ClientSecretFile = "${oauth2SecretDir}/client-secret";
  serverPasswordFile = "${config.services.actual.settings.dataDir}/server-password";
  actualOpenidBootstrapScript = pkgs.writeText "actual-openid-bootstrap.mjs" ''
    import { readFileSync } from "node:fs";
    import { pathToFileURL } from "node:url";

    const accountDb = await import(pathToFileURL(process.argv[2]).href);
    const loadConfig = await import(pathToFileURL(process.argv[3]).href);
    const password = readFileSync(process.argv[4], "utf8").trim();

    if (accountDb.d()) {
      const { error } = await accountDb.t({ password });
      if (error) {
        throw new Error("failed to bootstrap Actual password auth: " + error);
      }
    }

    const { error } = (await accountDb.r(loadConfig.t.getProperties())) || {};
    if (error) {
      throw new Error("failed to enable Actual OpenID auth: " + error);
    }
  '';
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.actual = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "actual";
    displayName = "Actual Budget";
    subdomain = "budget";
    defaultPort = 5006;
    defaultEnable = false;
  };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.actual = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "actual" cfg) ];
      backups.paths = [ config.services.actual.settings.dataDir ];
    };

    services.kanidm.provision = mkIf oidcEnabled {
      groups.actual-users.members = [ config.dot.primaryUser ];
      persons.${config.dot.primaryUser}.groups = [ "actual-users" ];
      systems.oauth2.actual = {
        displayName = "Actual Budget";
        originLanding = "https://${cfg.hostName}/";
        originUrl = "https://${cfg.hostName}/openid/callback";
        basicSecretFile = kanidmOauth2ClientSecretFile;
        preferShortUsername = true;
        scopeMaps.actual-users = [
          "openid"
          "email"
          "profile"
        ];
      };
    };

    services.actual = {
      enable = true;
      settings = {
        hostname = cfg.host;
        inherit (cfg) port;
        dataDir = "/var/lib/actual";
        openId = mkIf oidcEnabled {
          discoveryURL = "https://${kanidm.hostName}/oauth2/openid/actual/.well-known/openid-configuration";
          client_id = "actual";
          client_secret._secret = oauth2ClientSecretFile;
          server_hostname = "https://${cfg.hostName}";
          authMethod = "openid";
        };
      };
    };

    users = {
      groups.actual = { };
      users.actual = {
        isSystemUser = true;
        group = "actual";
      };
    };

    systemd.services = {
      kanidm = mkIf oidcEnabled {
        after = [ "actual-oauth2-secrets.service" ];
        requires = [ "actual-oauth2-secrets.service" ];
      };

      actual-oauth2-secrets = mkIf oidcEnabled {
        description = "Generate Actual Budget OAuth2 secrets";
        before = [
          "actual.service"
          "kanidm.service"
        ];
        requiredBy = [
          "actual.service"
          "kanidm.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ${pkgs.coreutils}/bin/install -d -m 0750 -o root -g kanidm ${kanidmOauth2SecretDir}
          ${pkgs.coreutils}/bin/install -d -m 0750 -o actual -g kanidm ${config.services.actual.settings.dataDir}
          ${pkgs.coreutils}/bin/chown actual:kanidm ${config.services.actual.settings.dataDir}
          ${pkgs.coreutils}/bin/chmod 0750 ${config.services.actual.settings.dataDir}
          ${pkgs.coreutils}/bin/install -d -m 0750 -o actual -g kanidm ${oauth2SecretDir}

          if [ ! -s ${kanidmOauth2ClientSecretFile} ]; then
            ${pkgs.openssl}/bin/openssl rand -base64 48 | ${pkgs.coreutils}/bin/tr -d '\n' > ${kanidmOauth2ClientSecretFile}
          fi

          ${pkgs.coreutils}/bin/chown root:kanidm ${kanidmOauth2ClientSecretFile}
          ${pkgs.coreutils}/bin/chmod 0440 ${kanidmOauth2ClientSecretFile}
          ${pkgs.coreutils}/bin/install -m 0400 -o actual -g actual ${kanidmOauth2ClientSecretFile} ${oauth2ClientSecretFile}
        '';
      };

      actual.environment = mkIf oidcEnabled {
        ACTUAL_OPENID_ENFORCE = "true";
        ACTUAL_USER_CREATION_MODE = "login";
      };

      actual = {
        after = mkIf oidcEnabled [
          "caddy.service"
          "kanidm.service"
        ];
        wants = mkIf oidcEnabled [
          "caddy.service"
          "kanidm.service"
        ];
        preStart = mkIf oidcEnabled (
          lib.mkAfter ''
            if [ ! -s ${serverPasswordFile} ]; then
              umask 077
              ${pkgs.openssl}/bin/openssl rand -base64 48 > ${serverPasswordFile}
            fi

            account_db="$(${pkgs.findutils}/bin/find ${config.services.actual.package}/lib/actual/packages/sync-server/chunks -maxdepth 1 -name 'account-db-*.js' -print -quit)"
            load_config="$(${pkgs.findutils}/bin/find ${config.services.actual.package}/lib/actual/packages/sync-server/chunks -maxdepth 1 -name 'load-config-*.js' -print -quit)"

            ${pkgs.nodejs_22}/bin/node ${actualOpenidBootstrapScript} "$account_db" "$load_config" ${serverPasswordFile}
          ''
        );
        serviceConfig.DynamicUser = lib.mkForce false;
      };
    };
  };
}
