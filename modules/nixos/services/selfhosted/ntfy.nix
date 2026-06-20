{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted.services.ntfy;
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.ntfy = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "ntfy";
    defaultPort = 2586;
  };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.ntfy = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "ntfy" cfg) ];
      backups.paths = [ "/var/lib/ntfy-sh" ];
    };

    services.ntfy-sh = {
      enable = true;
      settings = {
        base-url = "http://${cfg.hostName}";
        behind-proxy = true;
        listen-http = "${cfg.host}:${toString cfg.port}";
      };
    };
  };
}
