{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.grafana;
  kanidm = config.dot.selfhosted.services.kanidm;
  prometheus = config.dot.selfhosted.services.prometheus;
  loki = config.dot.selfhosted.services.loki;
  oidcEnabled = kanidm.enable;
  secretDir = "${config.services.grafana.dataDir}/secrets";
  secretKeyFile = "${secretDir}/secret-key";
  oauth2SecretFile = "${secretDir}/oauth2-client-secret";
  oauth2EnvFile = "${secretDir}/oauth2-env";
  dashboardDir = pkgs.runCommand "selfhosted-grafana-dashboards" { } ''
    mkdir -p "$out"
    cp ${dashboard} "$out/selfhosted-overview.json"
  '';
  dashboard = pkgs.writeText "selfhosted-overview.json" (
    builtins.toJSON {
      annotations.list = [ ];
      editable = false;
      graphTooltip = 0;
      panels = [
        {
          id = 1;
          title = "Load average";
          type = "timeseries";
          gridPos = {
            h = 8;
            w = 12;
            x = 0;
            y = 0;
          };
          targets = [
            {
              datasource.type = "prometheus";
              expr = ''node_load1{job="node"}'';
              refId = "A";
            }
          ];
        }
        {
          id = 2;
          title = "Memory available";
          type = "timeseries";
          gridPos = {
            h = 8;
            w = 12;
            x = 12;
            y = 0;
          };
          targets = [
            {
              datasource.type = "prometheus";
              expr = ''node_memory_MemAvailable_bytes{job="node"}'';
              refId = "A";
            }
          ];
          fieldConfig.defaults.unit = "bytes";
        }
        {
          id = 3;
          title = "System logs";
          type = "logs";
          gridPos = {
            h = 10;
            w = 24;
            x = 0;
            y = 8;
          };
          targets = [
            {
              datasource.type = "loki";
              expr = ''{unit=~"caddy.service|kanidm.service|grafana.service|vikunja.service"}'';
              refId = "A";
            }
          ];
        }
      ];
      refresh = "30s";
      schemaVersion = 41;
      tags = [ "selfhosted" ];
      templating.list = [ ];
      time = {
        from = "now-6h";
        to = "now";
      };
      title = "Selfhosted Overview";
      uid = "selfhosted-overview";
      version = 1;
    }
  );
  inherit (lib.lists) optional;
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.grafana = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "grafana";
    subdomain = "monitor";
    defaultPort = 3010;
    defaultEnable = false;
  };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.grafana = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "grafana" cfg) ];
      backups.paths = [ config.services.grafana.dataDir ];
    };

    services.kanidm.provision = mkIf oidcEnabled {
      groups.grafana-admins.members = [ "johnson" ];
      persons.johnson.groups = [ "grafana-admins" ];
      systems.oauth2.grafana = {
        displayName = "Grafana";
        originLanding = "https://${cfg.hostName}/login/generic_oauth";
        originUrl = "https://${cfg.hostName}/login/generic_oauth";
        basicSecretFile = oauth2SecretFile;
        preferShortUsername = true;
        scopeMaps.grafana-admins = [
          "openid"
          "email"
          "profile"
        ];
      };
    };

    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = cfg.host;
          http_port = cfg.port;
          domain = cfg.hostName;
          root_url = "https://${cfg.hostName}/";
        };
        security.secret_key = "$__file{${secretKeyFile}}";
        analytics.reporting_enabled = false;
        users = {
          allow_sign_up = false;
          allow_org_create = false;
        };
        auth = mkIf oidcEnabled {
          disable_login_form = true;
        };
        "auth.generic_oauth" = mkIf oidcEnabled {
          enabled = true;
          name = "Kanidm";
          auto_login = true;
          allow_sign_up = true;
          allow_assign_grafana_admin = true;
          client_id = "grafana";
          client_secret = "$__file{${oauth2SecretFile}}";
          scopes = "openid email profile";
          auth_url = "https://${kanidm.hostName}/ui/oauth2";
          token_url = "https://${kanidm.hostName}/oauth2/token";
          api_url = "https://${kanidm.hostName}/oauth2/openid/grafana/userinfo";
          use_pkce = true;
          login_attribute_path = "preferred_username";
          name_attribute_path = "name";
          email_attribute_path = "email";
          role_attribute_path = "'Admin'";
        };
      };
      provision = {
        enable = true;
        datasources.settings = {
          apiVersion = 1;
          prune = true;
          datasources =
            optional prometheus.enable {
              name = "Prometheus";
              type = "prometheus";
              access = "proxy";
              url = "http://${prometheus.host}:${toString prometheus.port}";
              isDefault = true;
            }
            ++ optional loki.enable {
              name = "Loki";
              type = "loki";
              access = "proxy";
              url = "http://${loki.host}:${toString loki.port}";
            };
        };
        dashboards.settings = {
          apiVersion = 1;
          providers = [
            {
              name = "selfhosted";
              folder = "Selfhosted";
              type = "file";
              disableDeletion = true;
              editable = false;
              options.path = dashboardDir;
            }
          ];
        };
      };
    };

    systemd.services.grafana-secret-key = {
      description = "Generate Grafana secrets";
      before = [
        "grafana.service"
        "kanidm.service"
      ];
      requiredBy = [ "grafana.service" ];
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.coreutils}/bin/chgrp kanidm ${config.services.grafana.dataDir}
        ${pkgs.coreutils}/bin/chmod 0750 ${config.services.grafana.dataDir}
        ${pkgs.coreutils}/bin/install -d -m 0750 -o grafana -g kanidm ${secretDir}

        if [ ! -s ${secretKeyFile} ]; then
          ${pkgs.openssl}/bin/openssl rand -base64 48 > ${secretKeyFile}
        fi

        if [ ! -s ${oauth2SecretFile} ]; then
          ${pkgs.openssl}/bin/openssl rand -base64 48 | ${pkgs.coreutils}/bin/tr -d '\n' > ${oauth2SecretFile}
        fi

        ${pkgs.coreutils}/bin/chown grafana:grafana ${secretKeyFile}
        ${pkgs.coreutils}/bin/chown grafana:kanidm ${oauth2SecretFile}
        ${pkgs.coreutils}/bin/chmod 0400 ${secretKeyFile}
        ${pkgs.coreutils}/bin/chmod 0440 ${oauth2SecretFile}

        {
          printf 'GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET=%s\n' "$(${pkgs.coreutils}/bin/cat ${oauth2SecretFile})"
        } > ${oauth2EnvFile}

        ${pkgs.coreutils}/bin/chown root:root ${oauth2EnvFile}
        ${pkgs.coreutils}/bin/chmod 0400 ${oauth2EnvFile}
      '';
    };

    systemd.services = {
      grafana = {
        after = [
          "grafana-secret-key.service"
          "kanidm.service"
        ];
        requires = [ "grafana-secret-key.service" ];
        serviceConfig.EnvironmentFile = mkIf oidcEnabled oauth2EnvFile;
      };
      kanidm = mkIf oidcEnabled {
        after = [ "grafana-secret-key.service" ];
        requires = [ "grafana-secret-key.service" ];
      };
    };
  };
}
