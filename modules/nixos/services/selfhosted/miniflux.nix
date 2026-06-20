{
  config,
  lib,
  self,
  ...
}:
let
  cfg = config.dot.selfhosted.services.miniflux;
  kanidm = config.dot.selfhosted.services.kanidm;
  oidcEnabled = kanidm.enable;
  secretsFile = "${self}/secrets/services/kanidm.yaml";
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.miniflux = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "miniflux";
    subdomain = "rss";
    defaultPort = 8082;
  };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.miniflux = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      gatus.endpoints = [ (lib.dot.mkGatusEndpoint "miniflux" cfg) ];
    };

    services.postgresql.authentication = ''
      host miniflux miniflux 127.0.0.1/32 trust
    '';

    sops.secrets.kanidm-oauth2-miniflux = mkIf oidcEnabled {
      sopsFile = secretsFile;
      key = "oauth2-miniflux";
      owner = "kanidm";
      group = "kanidm";
    };

    services.kanidm.provision = mkIf oidcEnabled {
      groups.miniflux-users.members = [ "johnson" ];
      persons.johnson.groups = [ "miniflux-users" ];
      systems.oauth2.miniflux = {
        displayName = "Miniflux";
        originLanding = "https://${cfg.hostName}/oauth2/oidc/redirect";
        originUrl = "https://${cfg.hostName}/oauth2/oidc/callback";
        basicSecretFile = config.sops.secrets.kanidm-oauth2-miniflux.path;
        preferShortUsername = true;
        scopeMaps.miniflux-users = [
          "openid"
          "email"
          "profile"
        ];
      };
    };

    services.miniflux = {
      enable = true;
      config = {
        BASE_URL = "https://${cfg.hostName}/";
        CREATE_ADMIN = 0;
        DATABASE_URL = "postgresql://miniflux@127.0.0.1/miniflux?sslmode=disable";
        LISTEN_ADDR = "${cfg.host}:${toString cfg.port}";
        OAUTH2_CLIENT_ID = mkIf oidcEnabled "miniflux";
        OAUTH2_OIDC_DISCOVERY_ENDPOINT = mkIf oidcEnabled "https://${kanidm.hostName}/oauth2/openid/miniflux";
        OAUTH2_PROVIDER = mkIf oidcEnabled "oidc";
        OAUTH2_REDIRECT_URL = mkIf oidcEnabled "https://${cfg.hostName}/oauth2/oidc/callback";
        OAUTH2_USER_CREATION = mkIf oidcEnabled 1;
        WATCHDOG = 0;
      };
    };

    sops.templates.miniflux-kanidm-env = mkIf oidcEnabled {
      owner = "root";
      group = "root";
      mode = "0400";
      content = ''
        OAUTH2_CLIENT_SECRET=${config.sops.placeholder.kanidm-oauth2-miniflux}
      '';
      restartUnits = [ "miniflux.service" ];
    };

    systemd.services.miniflux.serviceConfig = {
      EnvironmentFile = mkIf oidcEnabled [ config.sops.templates.miniflux-kanidm-env.path ];
      Type = lib.mkForce "simple";
      WatchdogSec = lib.mkForce 0;
    };
  };
}
