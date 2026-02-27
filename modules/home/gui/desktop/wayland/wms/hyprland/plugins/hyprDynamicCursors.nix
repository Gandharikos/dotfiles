{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.lists) elem;
  inherit (config.my.desktop.hyprland) plugins;
  enable = plugins.enable && elem "hypr-dynamic-cursors" plugins.list;
in {
  config = mkIf enable {
    wayland.windowManager.hyprland = {
      plugins = with pkgs.hyprlandPlugins; [hypr-dynamic-cursors];
      settings.plugin.dynamic-cursors = {
        enabled = true;
        mode = "stretch";
        stretch = {
          limit = 1500;
          # linear, quadratic, negative_quadratic
          function = "linear";
        };
        shake = {
          enabled = true;
          treshold = 1.0;
        };
      };
    };
  };
}
