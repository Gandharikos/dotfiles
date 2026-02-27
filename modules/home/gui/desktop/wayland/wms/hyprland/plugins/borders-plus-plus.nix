{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.lists) elem;
  inherit (config.my.desktop.hyprland) plugins;
  enable = plugins.enable && elem "borders-plus-plus" plugins.list;
in {
  config = mkIf enable {
    wayland.windowManager.hyprland = {
      plugins = with pkgs.hyprlandPlugins; [borders-plus-plus];
      settings.plugin.borders-plus-plus = {
        # TODO: change this, don't use hardcoded color
        # TODO: make this more senseable
        add_borders = 0;
        "col.border_1" = "rgb(ffffff)";
        "col.border_2" = "rgb(2222ff)";
        border_size_1 = 4;
        border_size_2 = -1;
        natural_rounding = "yes";
      };
    };
  };
}
