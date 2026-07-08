{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.dot.networking.vpn;
in
{
  options.dot.networking.vpn = {
    enable = mkEnableOption "Mullvad VPN" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    dot.networking.tailscale = {
      acceptDns = false;
      acceptRoutes = false;
    };

    services.mullvad-vpn = {
      enable = true;
      enableExcludeWrapper = false;
      package = if config.dot.gui.enable then pkgs.mullvad-vpn else pkgs.mullvad;
    };
  };
}
