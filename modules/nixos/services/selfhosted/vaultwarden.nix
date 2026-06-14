{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted.services.vaultwarden;
  selfhosted = config.dot.selfhosted;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types)
    bool
    listOf
    path
    str
    ;

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
      environmentFile = cfg.environmentFiles;
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
        USE_SYSLOG = true;
      };
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
