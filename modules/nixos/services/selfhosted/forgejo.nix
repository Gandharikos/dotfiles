{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.dot.selfhosted.services.forgejo;
  kanidm = config.dot.selfhosted.services.kanidm;
  redis = config.dot.selfhosted.services.redis;
  oidcEnabled = kanidm.enable;
  secretsFile = "${self}/secrets/services/kanidm.yaml";
  inherit (lib) getExe;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkOption;
  inherit (lib.types)
    bool
    port
    str
    ;
in
{
  options.dot.selfhosted.services.forgejo =
    lib.dot.mkSelfhostedServiceOptions {
      inherit config;
      name = "forgejo";
      subdomain = "git";
      defaultPort = 3000;
    }
    // {
      allowRegistration = mkOption {
        type = bool;
        default = false;
        description = "Whether public Forgejo account registration is allowed.";
      };

      redis = {
        enable = mkOption {
          type = bool;
          default = config.dot.selfhosted.services.redis.enable;
          description = "Whether Forgejo should use Redis-compatible cache and sessions.";
        };

        url = mkOption {
          type = str;
          default = "redis://${redis.host}:${toString cfg.redis.port}/0";
          description = "Redis-compatible URL used by Forgejo for cache and sessions.";
        };

        port = mkOption {
          type = port;
          default = 6371;
          description = "Redis-compatible port used by Forgejo.";
        };
      };
    };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.forgejo = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      gatus.endpoints = [ (lib.dot.mkGatusEndpoint "forgejo" cfg) ];
      backups.paths = [ config.services.forgejo.stateDir ];
    };

    sops.secrets = mkIf oidcEnabled {
      kanidm-oauth2-forgejo = {
        sopsFile = secretsFile;
        key = "oauth2-forgejo";
        owner = "kanidm";
        group = "kanidm";
      };
      forgejo-kanidm-oauth2 = {
        sopsFile = secretsFile;
        key = "oauth2-forgejo";
        owner = "forgejo";
        group = "forgejo";
      };
    };

    services.forgejo = {
      enable = true;
      database.type = "sqlite3";
      settings = mkMerge [
        {
          server = {
            DISABLE_SSH = true;
            DOMAIN = cfg.hostName;
            HTTP_ADDR = cfg.host;
            HTTP_PORT = cfg.port;
            ROOT_URL = "https://${cfg.hostName}/";
          };
          service = {
            DISABLE_REGISTRATION = if oidcEnabled then false else !cfg.allowRegistration;
            ALLOW_ONLY_EXTERNAL_REGISTRATION = oidcEnabled;
          };
        }
        (mkIf cfg.redis.enable {
          cache = {
            ADAPTER = "redis";
            HOST = cfg.redis.url;
          };
          session = {
            PROVIDER = "redis";
            PROVIDER_CONFIG = cfg.redis.url;
          };
        })
      ];
    };

    services.kanidm.provision = mkIf oidcEnabled {
      groups = {
        forgejo-users.members = [ "johnson" ];
        forgejo-admins.members = [ "johnson" ];
      };
      persons.johnson.groups = [
        "forgejo-users"
        "forgejo-admins"
      ];
      systems.oauth2.forgejo = {
        displayName = "Forgejo";
        originLanding = "https://${cfg.hostName}/user/oauth2/Kanidm";
        originUrl = "https://${cfg.hostName}/user/oauth2/Kanidm/callback";
        basicSecretFile = config.sops.secrets.kanidm-oauth2-forgejo.path;
        allowInsecureClientDisablePkce = true;
        preferShortUsername = true;
        scopeMaps.forgejo-users = [
          "openid"
          "email"
          "profile"
        ];
        claimMaps.forgejo_role = {
          joinType = "array";
          valuesByGroup.forgejo-admins = [ "admin" ];
        };
      };
    };

    systemd.services.forgejo = mkIf cfg.redis.enable {
      after = [ "redis-forgejo.service" ];
      wants = [ "redis-forgejo.service" ];
    };

    systemd.services.forgejo-kanidm-oauth = mkIf oidcEnabled {
      description = "Configure Forgejo Kanidm OAuth source";
      after = [
        "forgejo.service"
        "kanidm.service"
        "sops-install-secrets.service"
      ];
      requires = [
        "forgejo.service"
        "sops-install-secrets.service"
      ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.gnugrep ];
      serviceConfig = {
        Type = "oneshot";
        User = "forgejo";
        Group = "forgejo";
      };
      script = ''
        set -eu

        forgejo='${getExe config.services.forgejo.package}'
        config_file='${config.services.forgejo.customDir}/conf/app.ini'
        work_path='${config.services.forgejo.stateDir}'
        secret="$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.forgejo-kanidm-oauth2.path})"
        discovery='https://${kanidm.hostName}/oauth2/openid/forgejo/.well-known/openid-configuration'

        auth_id="$("$forgejo" admin auth list --config "$config_file" --work-path "$work_path" --min-width 1 \
          | ${pkgs.gawk}/bin/awk '
            NR > 1 && $2 == "Kanidm" {
              print $1
              exit
            }
          ')"

        common_args=(
          --config "$config_file"
          --work-path "$work_path"
          --name Kanidm
          --provider openidConnect
          --key forgejo
          --secret "$secret"
          --auto-discover-url "$discovery"
          --scopes "openid"
          --scopes "email"
          --scopes "profile"
          --group-claim-name forgejo_role
          --admin-group admin
          --skip-local-2fa
        )

        if [ -n "$auth_id" ]; then
          "$forgejo" admin auth update-oauth --id "$auth_id" "''${common_args[@]}"
        else
          "$forgejo" admin auth add-oauth "''${common_args[@]}"
        fi
      '';
    };
  };
}
