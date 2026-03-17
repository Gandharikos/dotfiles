{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.services.vpn;
in
{
  options.my.services.vpn = {
    enable = mkEnableOption "VPN" // {
      default = config.my.gui.enable;
    };
  };
  config = mkIf cfg.enable {
    services.mullvad-vpn.enable = true;

    environment.systemPackages = with pkgs; [
      mullvad
      mullvad-vpn
    ];
  };
}
