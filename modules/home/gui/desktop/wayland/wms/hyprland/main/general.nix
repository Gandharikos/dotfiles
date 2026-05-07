{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  # inherit (config.dot.machine) hasHidpi;
  cfg = config.dot.gui.desktop.hyprland;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      general = {
        border_size = 2;
        gaps_in = 10;
        gaps_out = 10;
        gaps_workspaces = 15;
        no_focus_fallback = false;
        resize_on_border = true;
        extend_border_grab_area = 10;
        hover_icon_on_border = true;
        # allow_tear = hasHidpi;
        resize_corner = 3;
        snap.enabled = true;
      };

      xwayland.force_zero_scaling = true;

      # debug.disable_logs = false;
    };
  };
}
