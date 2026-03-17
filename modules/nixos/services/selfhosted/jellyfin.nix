{
  lib,
  config,
  ...
}:
let
  cfg = config.my.services.jellyfin;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) int;
in
{
  options.my.services.jellyfin = {
    enable = mkEnableOption "jellyfin";
    port = mkOption {
      type = int;
      default = 8096;
      description = "The port on which Jellyfin will listen.";
    };
  };

  config = mkIf cfg.enable {
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
