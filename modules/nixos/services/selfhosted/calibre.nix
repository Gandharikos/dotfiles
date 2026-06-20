{
  lib,
  config,
  ...
}:
let
  cfg = config.dot.selfhosted.services.calibre;
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.calibre = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "calibre";
    defaultPort = 8080;
    defaultEnable = false;
  };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.calibre = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "calibre" cfg) ];
    };

    services.calibre-server.enable = true;

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
