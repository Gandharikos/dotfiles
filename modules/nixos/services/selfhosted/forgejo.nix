{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.forgejo;
  kanidm = config.dot.selfhosted.services.kanidm;
  oidcEnabled = kanidm.enable;
  inherit (lib) getExe;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkOption;
  inherit (lib.types)
    bool
    nullOr
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

      redisUrl = mkOption {
        type = nullOr str;
        default = null;
        description = "Redis-compatible URL used by Forgejo for cache and sessions.";
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
      backups.paths = [ config.services.forgejo.stateDir ];
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
        (mkIf (cfg.redisUrl != null) {
          cache = {
            ADAPTER = "redis";
            HOST = cfg.redisUrl;
          };
          session = {
            PROVIDER = "redis";
            PROVIDER_CONFIG = cfg.redisUrl;
          };
        })
      ];
    };

    systemd.services.forgejo = mkIf (cfg.redisUrl != null) {
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
