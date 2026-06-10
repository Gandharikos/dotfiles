{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.lists) optionals;
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
    services.mullvad-vpn.enable = true;

    environment.systemPackages =
      with pkgs;
      [
        mullvad
      ]
      ++ optionals config.dot.gui.enable [
        mullvad-vpn
      ];
  };
}
