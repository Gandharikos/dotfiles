{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted;
  gatus = cfg.services.gatus;
  inherit (lib.lists) optional;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types)
    listOf
    str
    submodule
    ;

  backupEndpoint = {
    name = "selfhosted-backup";
    url = "http://127.0.0.1:${toString cfg.backups.health.port}/health";
    interval = "5m";
    conditions = [ "[STATUS] == 200" ];
  };
in
{
  options.dot.selfhosted.services.gatus =
    lib.dot.mkSelfhostedServiceOptions {
      inherit config;
      name = "gatus";
      subdomain = "status";
      defaultPort = 8083;
      defaultEnable = config.dot.selfhosted.enable && config.dot.selfhosted.monitoring == "gatus";
    }
    // {
      endpoints = mkOption {
        type = listOf (submodule {
          options = {
            name = mkOption {
              type = str;
              description = "Gatus endpoint name.";
            };

            url = mkOption {
              type = str;
              description = "URL checked by Gatus.";
            };

            interval = mkOption {
              type = str;
              default = "1m";
              description = "Gatus check interval.";
            };

            conditions = mkOption {
              type = listOf str;
              default = [ "[STATUS] < 500" ];
              description = "Gatus endpoint conditions.";
            };
          };
        });
        default = [ ];
        description = "Endpoint definitions checked by Gatus.";
      };
    };

  config = mkIf gatus.enable {
    dot.selfhosted = {
      proxyBackends.gatus = {
        inherit (gatus)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      backups.paths = [ "/var/lib/gatus" ];
    };

    services.gatus = {
      enable = true;
      settings = {
        web.port = gatus.port;
        endpoints = gatus.endpoints ++ optional cfg.backups.health.enable backupEndpoint;
      };
    };
  };
}
