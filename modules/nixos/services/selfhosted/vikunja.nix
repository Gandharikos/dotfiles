{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.vikunja;
  kanidm = config.dot.selfhosted.services.kanidm;
  oidcEnabled = kanidm.enable;
  oidcDir = "/var/lib/vikunja-oidc";
  oidcSecretFile = "${oidcDir}/client-secret";
  oidcEnvFile = "${oidcDir}/env";
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.vikunja = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "vikunja";
    subdomain = "todo";
    defaultPort = 3456;
    defaultEnable = false;
  };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.vikunja = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "vikunja" cfg) ];
      backups.paths = [ "/var/lib/vikunja" ];
    };

    services.kanidm.provision = mkIf oidcEnabled {
      groups.vikunja-users.members = [ "johnson" ];
      persons.johnson.groups = [ "vikunja-users" ];
      systems.oauth2.vikunja = {
        displayName = "Vikunja";
        originLanding = "https://${cfg.hostName}/login?redirectToProvider=kanidm";
        originUrl = "https://${cfg.hostName}/auth/openid/kanidm";
        basicSecretFile = oidcSecretFile;
        allowInsecureClientDisablePkce = true;
        preferShortUsername = true;
        scopeMaps.vikunja-users = [
          "openid"
          "email"
          "profile"
        ];
      };
    };

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "vikunja" ];
      ensureUsers = [
        {
          name = "vikunja";
          ensureDBOwnership = true;
        }
      ];
      authentication = ''
        host vikunja vikunja 127.0.0.1/32 trust
      '';
    };

    services.vikunja = {
      enable = true;
      address = cfg.host;
      inherit (cfg) port;
      frontendHostname = cfg.hostName;
      frontendScheme = if config.dot.selfhosted.useHttps then "https" else "http";
      environmentFiles = mkIf oidcEnabled [ oidcEnvFile ];
      database = {
        type = "postgres";
        host = "127.0.0.1";
        user = "vikunja";
        database = "vikunja";
      };
      settings = {
        service = {
          enableregistration = false;
          enabletaskattachments = true;
        };
        auth = mkIf oidcEnabled {
          local.enabled = false;
          openid = {
            enabled = true;
            providers.kanidm = {
              name = "Kanidm";
              authurl = "https://${kanidm.hostName}/oauth2/openid/vikunja";
              clientid = "vikunja";
              scope = "openid email profile";
            };
          };
        };
      };
    };

    systemd.tmpfiles.settings.selfhosted-vikunja-oidc.${oidcDir}.d = mkIf oidcEnabled {
      user = "root";
      group = "kanidm";
      mode = "0750";
    };

    systemd.services = {
      vikunja-oidc-secret = mkIf oidcEnabled {
        description = "Generate Vikunja Kanidm OAuth secret";
        before = [
          "kanidm.service"
          "vikunja.service"
        ];
        requiredBy = [ "vikunja.service" ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          ${pkgs.coreutils}/bin/install -d -m 0750 -o root -g kanidm ${oidcDir}

          if [ ! -s ${oidcSecretFile} ]; then
            ${pkgs.openssl}/bin/openssl rand -base64 48 | ${pkgs.coreutils}/bin/tr -d '\n' > ${oidcSecretFile}
          fi

          ${pkgs.coreutils}/bin/chown root:kanidm ${oidcSecretFile}
          ${pkgs.coreutils}/bin/chmod 0440 ${oidcSecretFile}

          {
            printf 'VIKUNJA_AUTH_OPENID_PROVIDERS_KANIDM_CLIENTSECRET=%s\n' "$(${pkgs.coreutils}/bin/cat ${oidcSecretFile})"
          } > ${oidcEnvFile}

          ${pkgs.coreutils}/bin/chown root:root ${oidcEnvFile}
          ${pkgs.coreutils}/bin/chmod 0400 ${oidcEnvFile}
        '';
      };

      kanidm = mkIf oidcEnabled {
        after = [ "vikunja-oidc-secret.service" ];
        requires = [ "vikunja-oidc-secret.service" ];
      };

      vikunja = {
        after = [
          "postgresql.service"
        ]
        ++ lib.optional oidcEnabled "vikunja-oidc-secret.service";
        requires = [
          "postgresql.service"
        ]
        ++ lib.optional oidcEnabled "vikunja-oidc-secret.service";
      };
    };
  };
}
