{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted.services.prometheus;
  postgresql = config.dot.selfhosted.services.postgresql;
  inherit (lib.lists) optional;
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.prometheus = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "prometheus";
    defaultPort = 9090;
    defaultEnable = false;
  };

  config = mkIf cfg.enable {
    dot.selfhosted.backups.paths = [ "/var/lib/prometheus2" ];

    services.prometheus = {
      enable = true;
      listenAddress = cfg.host;
      inherit (cfg) port;
      retentionTime = "15d";
      exporters = {
        node = {
          enable = true;
          listenAddress = cfg.host;
          enabledCollectors = [ "systemd" ];
        };
        postgres = mkIf postgresql.enable {
          enable = true;
          listenAddress = cfg.host;
          runAsLocalSuperUser = true;
        };
      };
      scrapeConfigs = [
        {
          job_name = "prometheus";
          static_configs = [ { targets = [ "${cfg.host}:${toString cfg.port}" ]; } ];
        }
        {
          job_name = "node";
          static_configs = [ { targets = [ "${cfg.host}:9100" ]; } ];
        }
      ]
      ++ optional postgresql.enable {
        job_name = "postgresql";
        static_configs = [ { targets = [ "${cfg.host}:9187" ]; } ];
      };
    };
  };
}
