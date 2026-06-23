{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted.services.immich;
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) path;
in
{
  options.dot.selfhosted.services.immich =
    lib.dot.mkSelfhostedServiceOptions {
      inherit config;
      name = "immich";
      displayName = "Immich";
      subdomain = "photo";
      defaultPort = 2283;
      defaultEnable = false;
    }
    // {
      mediaLocation = mkOption {
        type = path;
        default = "/var/lib/immich";
        description = "Directory used by Immich to store uploaded photos and videos.";
      };

      machineLearning.enable = mkEnableOption "Immich machine learning" // {
        default = false;
      };
    };

  config = mkIf cfg.enable {
    dot.selfhosted = {
      proxyBackends.immich = {
        inherit (cfg)
          host
          hostName
          localHostAlias
          port
          scheme
          ;
      };
      services.gatus.endpoints = [ (lib.dot.mkGatusEndpoint "immich" cfg) ];
      backups.paths = [ cfg.mediaLocation ];
    };

    services.immich = {
      enable = true;
      inherit (cfg) host port mediaLocation;

      machine-learning.enable = cfg.machineLearning.enable;

      settings = {
        machineLearning.enabled = cfg.machineLearning.enable;
        newVersionCheck.enabled = false;
        server.externalDomain = "https://${cfg.hostName}";
      };

      environment.IMMICH_MACHINE_LEARNING_ENABLED =
        if cfg.machineLearning.enable then "true" else "false";

      database = {
        enable = true;
        createDB = true;
      };

      redis.enable = true;
      openFirewall = mkDefault false;
    };
  };
}
