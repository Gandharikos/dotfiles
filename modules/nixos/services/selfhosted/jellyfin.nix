{
  lib,
  config,
  ...
}:
let
  cfg = config.dot.selfhosted.services.jellyfin;
  inherit (lib.modules) mkIf;
in
{
  options.dot.selfhosted.services.jellyfin = lib.dot.mkSelfhostedServiceOptions {
    inherit config;
    name = "jellyfin";
    defaultPort = 8096;
    defaultEnable = false;
  };

  config = mkIf cfg.enable {
    users.groups.media = { };

    services.jellyfin = {
      enable = true;
      group = "media";
      openFirewall = true;
    };

    networking.firewall = {
      allowedTCPPorts = [ cfg.port ];
      allowedUDPPorts = [ cfg.port ];
    };
  };
}
