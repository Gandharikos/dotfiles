{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.lists) elem;
  inherit (config.my.desktop.hyprland) plugins;
  enable = plugins.enable && elem "hyprwinwrap" plugins.list;
in {
  config = mkIf enable {
    wayland.windowManager.hyprland = {
      plugins = with pkgs.hyprlandPlugins; [hyprwinwrap];
      settings.plugin.hyprwinwrap = {
        # class is an EXACT match and NOT a regex!
        # TODO: use this more sensefully
        class = "wallpaper";
      };
    };
  };
}
