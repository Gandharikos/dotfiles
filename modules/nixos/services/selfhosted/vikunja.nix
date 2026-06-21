{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted.services.vikunja;
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.vikunja = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "vikunja";
    subdomain = "todo";
    defaultPort = 3456;
    defaultEnable = false;
  };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.vikunja = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "vikunja" cfg) ];
      backups.paths = [ "/var/lib/vikunja" ];
    };

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "vikunja" ];
      ensureUsers = [
        {
          name = "vikunja";
          ensureDBOwnership = true;
        }
      ];
      authentication = ''
        host vikunja vikunja 127.0.0.1/32 trust
      '';
    };

    services.vikunja = {
      enable = true;
      address = cfg.host;
      inherit (cfg) port;
      frontendHostname = cfg.hostName;
      frontendScheme = if config.dot.selfhosted.useHttps then "https" else "http";
      database = {
        type = "postgres";
        host = "127.0.0.1";
        user = "vikunja";
        database = "vikunja";
      };
      settings = {
        service = {
          enableregistration = false;
          enabletaskattachments = true;
        };
      };
    };

    systemd.services.vikunja = {
      after = [ "postgresql.service" ];
      requires = [ "postgresql.service" ];
    };
  };
}
