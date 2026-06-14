{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted.services.wakapi;
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.wakapi = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "wakapi";
    defaultPort = 3003;
  };

  config = mkIf cfg.enable {
    services.wakapi = {
      enable = true;
      database.createLocally = true;
      settings = {
        server = {
          listen_ipv4 = cfg.host;
          inherit (cfg) port;
          public_url = "http://${cfg.hostName}";
        };
        db = {
          dialect = "postgres";
          host = "127.0.0.1";
          name = "wakapi";
          password = "";
          port = 5432;
          user = "wakapi";
        };
      };
    };
  };
}
