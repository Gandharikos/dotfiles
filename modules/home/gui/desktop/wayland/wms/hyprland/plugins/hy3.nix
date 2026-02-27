{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.lists) elem;
  inherit (config.my.desktop.hyprland) plugins;
  enable = plugins.enable && elem "hy3" plugins.list;
in {
  config = mkIf enable {
    wayland.windowManager.hyprland = {
      plugins = with pkgs.hyprlandPlugins; [hy3];
      settings.plugin.hy3 = {
        autotile.enable = true;
      };
    };
  };
}
