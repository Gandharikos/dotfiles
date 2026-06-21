{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.grafana;
  prometheus = config.dot.selfhosted.services.prometheus;
  loki = config.dot.selfhosted.services.loki;
  secretKeyFile = "${config.services.grafana.dataDir}/secret-key";
  inherit (lib.lists) optional;
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.grafana = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "grafana";
    defaultPort = 3010;
    defaultEnable = false;
  };

  config = mkIf cfg.enable {
    dot.selfhosted.backups.paths = [ config.services.grafana.dataDir ];

    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = cfg.host;
          http_port = cfg.port;
          domain = "localhost";
          root_url = "http://localhost:${toString cfg.port}/";
        };
        security.secret_key = "$__file{${secretKeyFile}}";
        analytics.reporting_enabled = false;
        users = {
          allow_sign_up = false;
          allow_org_create = false;
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
      };
    };

    systemd.services.grafana-secret-key = {
      description = "Generate Grafana secret key";
      before = [ "grafana.service" ];
      requiredBy = [ "grafana.service" ];
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.coreutils}/bin/install -d -m 0750 -o grafana -g grafana ${config.services.grafana.dataDir}
        if [ ! -s ${secretKeyFile} ]; then
          ${pkgs.openssl}/bin/openssl rand -base64 48 > ${secretKeyFile}
        fi
        ${pkgs.coreutils}/bin/chown grafana:grafana ${secretKeyFile}
        ${pkgs.coreutils}/bin/chmod 0400 ${secretKeyFile}
      '';
    };
  };
}
