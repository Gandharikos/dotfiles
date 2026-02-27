{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.lists) elem;
  inherit (config.my.desktop.hyprland) plugins;
  enable = plugins.enable && elem "hyprbars" plugins.list;
in {
  config = mkIf enable {
    wayland.windowManager.hyprland = {
      plugins = with pkgs.hyprlandPlugins; [hyprbars];
      settings.plugin.hyprbars = {
        bar_height = 20;
        bar_precedence_over_border = true;
      };
    };
  };
}
