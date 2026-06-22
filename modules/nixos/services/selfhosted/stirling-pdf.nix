{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.stirling-pdf;
  kanidm = config.dot.selfhosted.services.kanidm;
  oidcEnabled = kanidm.enable;
  kanidmOauth2SecretDir = "/var/lib/kanidm/oauth2/stirling-pdf";
  kanidmOauth2ClientSecretFile = "${kanidmOauth2SecretDir}/client-secret";
  oauth2SecretDir = "/var/lib/stirling-pdf/oauth2";
  oauth2EnvFile = "${oauth2SecretDir}/env";
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.stirling-pdf = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "stirling-pdf";
    displayName = "Stirling PDF";
    subdomain = "pdf";
    defaultPort = 5008;
    defaultEnable = false;
  };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.stirling-pdf = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "stirling-pdf" cfg) ];
      backups.paths = [ "/var/lib/stirling-pdf" ];
    };

    services.kanidm.provision = mkIf oidcEnabled {
      groups.stirling-pdf-users.members = [ config.dot.primaryUser ];
      persons.${config.dot.primaryUser}.groups = [ "stirling-pdf-users" ];
      systems.oauth2.stirling-pdf = {
        displayName = "Stirling PDF";
        originLanding = "https://${cfg.hostName}/login";
        originUrl = "https://${cfg.hostName}/login/oauth2/code/kanidm";
        basicSecretFile = kanidmOauth2ClientSecretFile;
        preferShortUsername = true;
        scopeMaps.stirling-pdf-users = [
          "openid"
          "email"
          "profile"
        ];
      };
    };

    services.stirling-pdf = {
      enable = true;
      environment = {
        SERVER_PORT = cfg.port;
        SECURITY_ENABLELOGIN = true;
        SECURITY_LOGINMETHOD = "all";
        SECURITY_OAUTH2_AUTOCREATEUSER = true;
        SECURITY_OAUTH2_BLOCKREGISTRATION = false;
        SECURITY_OAUTH2_CLIENTID = "stirling-pdf";
        SECURITY_OAUTH2_ENABLED = oidcEnabled;
        SECURITY_OAUTH2_ISSUER = "https://${kanidm.hostName}/oauth2/openid/stirling-pdf";
        SECURITY_OAUTH2_PROVIDER = "kanidm";
        SECURITY_OAUTH2_SCOPES = "openid, profile, email";
        SECURITY_OAUTH2_USEASUSERNAME = "preferred_username";
        SYSTEM_ROOTURIPATH = "/";
      };
      environmentFiles = mkIf oidcEnabled [ oauth2EnvFile ];
    };

    systemd.services = {
      kanidm = mkIf oidcEnabled {
        after = [ "stirling-pdf-oauth2-secrets.service" ];
        requires = [ "stirling-pdf-oauth2-secrets.service" ];
      };

      stirling-pdf-oauth2-secrets = mkIf oidcEnabled {
        description = "Generate Stirling PDF OAuth2 secrets";
        before = [
          "kanidm.service"
          "stirling-pdf.service"
        ];
        requiredBy = [
          "kanidm.service"
          "stirling-pdf.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ${pkgs.coreutils}/bin/install -d -m 0750 -o root -g kanidm ${kanidmOauth2SecretDir}
          ${pkgs.coreutils}/bin/install -d -m 0750 -o root -g kanidm ${oauth2SecretDir}

          if [ ! -s ${kanidmOauth2ClientSecretFile} ]; then
            ${pkgs.openssl}/bin/openssl rand -base64 48 | ${pkgs.coreutils}/bin/tr -d '\n' > ${kanidmOauth2ClientSecretFile}
          fi

          ${pkgs.coreutils}/bin/chown root:kanidm ${kanidmOauth2ClientSecretFile}
          ${pkgs.coreutils}/bin/chmod 0440 ${kanidmOauth2ClientSecretFile}
          printf 'SECURITY_OAUTH2_CLIENTSECRET=%s\n' "$(${pkgs.coreutils}/bin/cat ${kanidmOauth2ClientSecretFile})" > ${oauth2EnvFile}
          ${pkgs.coreutils}/bin/chown root:root ${oauth2EnvFile}
          ${pkgs.coreutils}/bin/chmod 0400 ${oauth2EnvFile}
        '';
      };
    };
  };
}
