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
  enable = plugins.enable && elem "hyprfocus" plugins.list;
in
{
  config = mkIf enable {
    wayland.windowManager.hyprland = {
      plugins = with pkgs.hyprlandPlugins; [ hyprfocus ];

      settings = {
        bindd = [ "$mod SHIFT, SPACE, Animate Focus, animatefocused" ];
        plugin.hyprfocus = {
          enabled = "yes";
          keyboard_focus_animation = "shrink";
          mouse_focus_animation = "flash";
          bezier = [
            "bezIn, 0.5, 0.0, 1.0, 0.5"
            "bezOut, 0.0, 0.5, 0.5, 1.0"
            "overshot, 0.05, 0.9, 0.1, 1.05"
            "smoothOut, 0.36, 0, 0.66, -0.56"
            "smoothIn, 0.25, 1, 0.5, 1"
            "realsmooth, 0.28, 0.29, 0.69, 1.08"
          ];
          flash = {
            flash_opacity = 0.8;
            in_bezier = "realsmooth";
            in_speed = 0.5;
            out_bezier = "realsmooth";
            out_speed = 3;
          };
          shrink = {
            shrink_percentage = 0.98;
            in_bezier = "bezIn";
            in_speed = 1;
            out_bezier = "bezOut";
            out_speed = 2;
          };
        };
      };
    };
  };
}
