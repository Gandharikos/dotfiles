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

  backupEndpoint = {
    name = "selfhosted-backup";
    url = "http://127.0.0.1:${toString cfg.backups.health.port}/health";
    interval = "5m";
    conditions = [ "[STATUS] == 200" ];
  };
in
{
  options.dot.selfhosted.services.gatus = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "gatus";
    subdomain = "status";
    defaultPort = 8083;
    defaultEnable = config.dot.selfhosted.enable && config.dot.selfhosted.monitoring == "gatus";
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
        endpoints = cfg.gatus.endpoints ++ optional cfg.backups.health.enable backupEndpoint;
      };
    };
  };
}
