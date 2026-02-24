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
      input = {
        kb_layout = "us";
        kb_options = "ctrl:nocaps";
        # focus change on cursor move
        follow_mouse = 1;
        accel_profile = "flat";
        repeat_rate = 25;
        repeat_delay = 200;

        touchpad = {
          natural_scroll = true;
          scroll_factor = 0.2;
        };
      };

      # touchpad gestures
      gestures = {
        workspace_swipe_forever = true;
      };
      gesture = [
        "3, horizontal, workspace"
      ];

      cursor = {
        no_hardware_cursors = true;
      };
    };
  };
}
