{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted.services.uptimeKuma;
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.uptimeKuma = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "uptimeKuma";
    displayName = "uptime-kuma";
    defaultPort = 3001;
    defaultEnable = config.dot.selfhosted.enable && config.dot.selfhosted.monitoring == "uptime-kuma";
  };

  config = mkIf cfg.enable {
    dot.selfhosted.proxyBackends.uptimeKuma = {
      inherit (cfg)
        host
        hostName
        localHostAlias
        port
        scheme
        ;
    };

    services.uptime-kuma = {
      enable = true;
      settings = {
        HOST = cfg.host;
        PORT = toString cfg.port;
      };
    };
  };
}
