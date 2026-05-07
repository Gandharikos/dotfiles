{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.lists) elem;
  inherit (config.dot.gui.desktop.hyprland) plugins;
  enable = plugins.enable && elem "hyprexpo" plugins.list;
in
{
  config = mkIf enable {
    wayland.windowManager.hyprland = {
      plugins = with pkgs.hyprlandPlugins; [ hyprexpo ];

      settings = {
        bindd = [
          "$mod, GRAVE, Toggle Expo, hyprexpo:expo, toggle"
        ];
        plugin.hyprexpo = {
          rows = 3;
          columns = 3;

          gap_size = 4;
          # TODO: change this, don't use hardcoded color
          bg_col = "rgb(111111)";
          workspace_method = "center current";

          enable_gesture = true;
          gesture_fingers = 3;
          gesture_distance = 300;
          gesture_positive = true;
        };
      };
    };
  };
}
