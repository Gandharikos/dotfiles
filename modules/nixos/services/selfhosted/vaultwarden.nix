{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted.services.vaultwarden;
  selfhosted = config.dot.selfhosted;
  kanidm = config.dot.selfhosted.services.kanidm;
  oidcEnabled = kanidm.enable;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types)
    bool
    listOf
    path
    str
    ;
  inherit (lib.lists) optionals;

  publicUrl =
    if selfhosted.useHttps then
      "https://${cfg.hostName}"
    else if selfhosted.domain == "localhost" then
      "http://localhost"
    else
      "http://${cfg.hostName}";
in
{
  options.dot.selfhosted.services.vaultwarden =
    lib.dot.mkSelfhostedServiceOptions {
      inherit config;
      name = "vaultwarden";
      subdomain = "vault";
      defaultPort = 8222;
    }
    // {
      allowRegistration = mkOption {
        type = bool;
        default = false;
        description = "Whether public Vaultwarden account registration is allowed.";
      };

      allowInvitations = mkOption {
        type = bool;
        default = true;
        description = "Whether existing users can invite new Vaultwarden users.";
      };

      verifySignups = mkOption {
        type = bool;
        default = true;
        description = "Whether Vaultwarden signups must verify their email address.";
      };

      dataDir = mkOption {
        type = str;
        default = "/var/lib/vaultwarden";
        description = "Vaultwarden persistent data directory.";
      };

      environmentFiles = mkOption {
        type = listOf path;
        default = [ ];
        description = "Additional Vaultwarden environment files for secrets such as SMTP_PASSWORD or ADMIN_TOKEN.";
      };
    };

  config = mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      ensureDatabases = [ "vaultwarden" ];
      ensureUsers = [
        {
          name = "vaultwarden";
          ensureDBOwnership = true;
        }
      ];
      authentication = ''
        host vaultwarden vaultwarden 127.0.0.1/32 trust
      '';
    };

    services.vaultwarden = {
      enable = true;
      dbBackend = "postgresql";
      environmentFile =
        cfg.environmentFiles ++ optionals oidcEnabled [ config.sops.templates.vaultwarden-kanidm-env.path ];
      config = {
        DATABASE_URL = "postgresql://vaultwarden@127.0.0.1/vaultwarden?sslmode=disable";
        DATA_FOLDER = cfg.dataDir;
        DOMAIN = publicUrl;
        ENABLE_WEBSOCKET = true;
        EXTENDED_LOGGING = true;
        INVITATIONS_ALLOWED = cfg.allowInvitations;
        LOG_LEVEL = "warn";
        ROCKET_ADDRESS = cfg.host;
        ROCKET_LOG = "critical";
        ROCKET_PORT = cfg.port;
        SHOW_PASSWORD_HINT = false;
        SIGNUPS_ALLOWED = cfg.allowRegistration;
        SIGNUPS_VERIFY = cfg.verifySignups;
        SSO_AUTHORITY = mkIf oidcEnabled "https://${kanidm.hostName}/oauth2/openid/vaultwarden";
        SSO_CLIENT_ID = mkIf oidcEnabled "vaultwarden";
        SSO_ENABLED = oidcEnabled;
        SSO_SCOPES = mkIf oidcEnabled "email profile";
        SSO_SIGNUPS_ALLOWED = oidcEnabled;
        SSO_SIGNUPS_MATCH_EMAIL = oidcEnabled;
        USE_SYSLOG = true;
      };
    };

    sops.templates.vaultwarden-kanidm-env = mkIf oidcEnabled {
      owner = "root";
      group = "root";
      mode = "0400";
      content = ''
        SSO_CLIENT_SECRET=${config.sops.placeholder.kanidm-oauth2-vaultwarden}
      '';
      restartUnits = [ "vaultwarden.service" ];
    };

    systemd.services.vaultwarden = {
      after = [ "postgresql.service" ];
      requires = [ "postgresql.service" ];
      serviceConfig.ReadWritePaths = [ cfg.dataDir ];
    };

    systemd.tmpfiles.settings.selfhosted-vaultwarden = {
      ${cfg.dataDir}.d = {
        user = "vaultwarden";
        group = "vaultwarden";
        mode = "0700";
      };
    };
  };
}
