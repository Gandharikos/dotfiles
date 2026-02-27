{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.services.vpn;
in {
  options.my.services.ssh = {
    enable =
      mkEnableOption "VPN"
      // {
        default = config.my.desktop.enable;
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
