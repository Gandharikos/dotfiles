{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.lists) elem;
  inherit (config.my.desktop.hyprland) plugins;
  enable = plugins.enable && elem "hyprgrass" plugins.list;
in {
  config = mkIf enable {
    wayland.windowManager.hyprland = {
      plugins = with pkgs.hyprlandPlugins; [hyprgrass];
      settings = {
        plugin.touch_gestures = {
          sensitivity = 6.0;
          workspace_swipe_fingers = 3;
          worskpace_swipe_edge = "r";
        };
        gestures = {
          workspace_swipe = true;
          workspace_swip_cancel_ratio = 0.15;
        };
      };
    };
  };
}
