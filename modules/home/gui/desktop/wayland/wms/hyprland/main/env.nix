{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.my.desktop.hyprland;
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      env = [
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "WLR_NO_HARDWARE_CURSORS,1"
        # NOTE: we used this on hardware configarture
        # for hyprland with nvidia gpu, ref https://wiki.hyprland.org/Nvidia/
        # "LIBVA_DRIVER_NAME,nvidia"
        # "GBM_BACKEND,nvidia-drm"
        # "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        # fix https://github.com/hyprwm/Hyprland/issues/1520
        # "WLR_NO_HARDWARE_CURSORS,1"
      ];
    };
  };
}
