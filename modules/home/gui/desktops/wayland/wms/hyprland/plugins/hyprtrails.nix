{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.lists) elem;
  inherit (config.my.desktop.hyprland) plugins;
  enable = plugins.enable && elem "hyprtails" plugins.list;
in {
  config = mkIf enable {
    wayland.windowManager.hyprland = {
      plugins = with pkgs.hyprlandPlugins; [hyprtails];

      settings.plugin.hyprtrails = {
        # TODO: change this, don't use hardcoded color
        color = "rgb(f5bde5}";
      };
    };
  };
}
