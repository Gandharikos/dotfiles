{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.dot.selfhosted.services.kanidm;
  secretsFile = "${self}/secrets/services/kanidm.yaml";
  certDir = "/var/lib/kanidm/tls";
  cert = "${certDir}/fullchain.pem";
  key = "${certDir}/key.pem";
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.kanidm = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "kanidm";
    subdomain = "sso";
    defaultPort = 8443;
    scheme = "https";
  };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.kanidm = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      gatus.endpoints = [ (lib.dot.mkGatusEndpoint "kanidm" cfg) ];
      backups.paths = [ "/var/lib/kanidm" ];
    };

    sops.secrets = {
      kanidm-admin-password = {
        sopsFile = secretsFile;
        key = "admin-password";
        owner = "kanidm";
        group = "kanidm";
      };
      kanidm-idm-admin-password = {
        sopsFile = secretsFile;
        key = "idm-admin-password";
        owner = "kanidm";
        group = "kanidm";
      };
    };

    services.kanidm = {
      package = pkgs.kanidmWithSecretProvisioning_1_10;
      server = {
        enable = true;
        settings = {
          version = "2";
          domain = cfg.hostName;
          origin = "https://${cfg.hostName}";
          bindaddress = "${cfg.host}:${toString cfg.port}";
          ldapbindaddress = null;
          tls_chain = cert;
          tls_key = key;
          online_backup = {
            path = "/var/lib/kanidm/backups";
            schedule = "00 22 * * *";
            versions = 7;
          };
        };
      };
      client = {
        enable = true;
        settings.uri = "https://${cfg.hostName}";
      };
      provision = {
        enable = true;
        adminPasswordFile = config.sops.secrets.kanidm-admin-password.path;
        idmAdminPasswordFile = config.sops.secrets.kanidm-idm-admin-password.path;
        instanceUrl = "https://${cfg.host}:${toString cfg.port}";
        acceptInvalidCerts = true;
        groups = {
          selfhosted-users.members = [ "johnson" ];
        };
        persons.johnson = {
          displayName = "Johnson";
          legalName = "Johnson Hu";
          mailAddresses = [ config.dot.admin.email ];
          groups = [ "selfhosted-users" ];
        };
      };
    };

    systemd.services = {
      kanidm-selfsigned-cert = {
        description = "Generate local self-signed TLS certificate for Kanidm";
        before = [ "kanidm.service" ];
        requiredBy = [ "kanidm.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ${pkgs.coreutils}/bin/install -d -m 0750 -o kanidm -g kanidm ${certDir}
          if [ ! -s ${cert} ] || [ ! -s ${key} ]; then
            ${pkgs.openssl}/bin/openssl req \
              -x509 \
              -newkey rsa:4096 \
              -sha256 \
              -days 3650 \
              -nodes \
              -keyout ${key} \
              -out ${cert} \
              -subj "/CN=${cfg.hostName}" \
              -addext "subjectAltName=DNS:${cfg.hostName},DNS:localhost,IP:127.0.0.1"
          fi
          ${pkgs.coreutils}/bin/chown kanidm:kanidm ${cert} ${key}
          ${pkgs.coreutils}/bin/chmod 0440 ${cert} ${key}
        '';
      };

      kanidm = {
        after = [ "kanidm-selfsigned-cert.service" ];
        requires = [ "kanidm-selfsigned-cert.service" ];
      };
    };

    networking.hosts."127.0.0.1" = [ cfg.hostName ];
  };
}
