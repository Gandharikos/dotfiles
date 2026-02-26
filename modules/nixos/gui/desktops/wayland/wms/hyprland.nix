{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf mkForce;
  inherit (lib.meta) getExe;
  inherit (lib.my) isHyprland;
  uwsm' = getExe pkgs.uwsm;
  enable = isHyprland config;
in {
  config = mkIf enable {
    services.displayManager.defaultSession = "hyprland-uwsm";

    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    my.desktop.exec = "${uwsm'} start hyprland-uwsm.desktop";

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
      ];

      # xdg-desktop-wlr (this section) is no longer needed, xdg-desktop-portal-hyprland
      # will (and should) override this one
      wlr.enable = mkForce false;
    };
  };
}
