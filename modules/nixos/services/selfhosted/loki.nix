{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted.services.loki;
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.loki = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "loki";
    defaultPort = 3100;
    defaultEnable = false;
  };

  config = mkIf cfg.enable {
    dot.selfhosted.backups.paths = [ config.services.loki.dataDir ];

    services.loki = {
      enable = true;
      configuration = {
        auth_enabled = false;
        server = {
          http_listen_address = cfg.host;
          http_listen_port = cfg.port;
          grpc_listen_address = cfg.host;
          grpc_listen_port = 9096;
        };
        common = {
          path_prefix = config.services.loki.dataDir;
          instance_addr = cfg.host;
          replication_factor = 1;
          ring.kvstore.store = "inmemory";
          storage.filesystem = {
            chunks_directory = "${config.services.loki.dataDir}/chunks";
            rules_directory = "${config.services.loki.dataDir}/rules";
          };
        };
        schema_config.configs = [
          {
            from = "2024-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
        limits_config = {
          retention_period = "168h";
          allow_structured_metadata = false;
        };
        compactor = {
          working_directory = "${config.services.loki.dataDir}/compactor";
          retention_enabled = true;
          delete_request_store = "filesystem";
        };
      };
    };

    environment.etc."alloy/config.alloy".text = ''
      loki.write "local" {
        endpoint {
          url = "http://${cfg.host}:${toString cfg.port}/loki/api/v1/push"
        }
      }

      discovery.relabel "journal" {
        targets = []

        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "unit"
        }

        rule {
          source_labels = ["__journal_priority_keyword"]
          target_label  = "level"
        }

        rule {
          source_labels = ["__journal__hostname"]
          target_label  = "host"
        }
      }

      loki.source.journal "systemd" {
        max_age       = "24h"
        relabel_rules = discovery.relabel.journal.rules
        forward_to    = [loki.write.local.receiver]
      }
    '';

    services.alloy = {
      enable = true;
      extraFlags = [ "--server.http.listen-addr=${cfg.host}:12345" ];
    };

    systemd.services.alloy = {
      after = [ "loki.service" ];
      wants = [ "loki.service" ];
      path = [ pkgs.systemd ];
    };
  };
}
