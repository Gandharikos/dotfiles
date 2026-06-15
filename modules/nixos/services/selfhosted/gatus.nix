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

  mkEndpoint = name: service: {
    inherit name;
    url = "${service.scheme}://${service.host}:${toString service.port}";
    interval = "1m";
    conditions = [ "[STATUS] < 500" ];
  };

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
    defaultPort = 8083;
    defaultEnable = config.dot.selfhosted.enable && config.dot.selfhosted.monitoring == "gatus";
  };

  config = mkIf gatus.enable {
    services.gatus = {
      enable = true;
      settings = {
        web.port = gatus.port;
        endpoints =
          optional cfg.services.vaultwarden.enable (mkEndpoint "vaultwarden" cfg.services.vaultwarden)
          ++ optional cfg.services.forgejo.enable (mkEndpoint "forgejo" cfg.services.forgejo)
          ++ optional cfg.services.ntfy.enable (mkEndpoint "ntfy" cfg.services.ntfy)
          ++ optional cfg.services.miniflux.enable (mkEndpoint "miniflux" cfg.services.miniflux)
          ++ optional cfg.services.wakapi.enable (mkEndpoint "wakapi" cfg.services.wakapi)
          ++ optional cfg.services.linkwarden.enable (mkEndpoint "linkwarden" cfg.services.linkwarden)
          ++ optional cfg.services.kanidm.enable (mkEndpoint "kanidm" cfg.services.kanidm)
          ++ optional cfg.services.jellyfin.enable (mkEndpoint "jellyfin" cfg.services.jellyfin)
          ++ optional cfg.services.calibre.enable (mkEndpoint "calibre" cfg.services.calibre)
          ++ optional cfg.backups.health.enable backupEndpoint;
      };
    };
  };
}
