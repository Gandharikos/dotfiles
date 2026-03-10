{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.my) rgba gradient;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (config.my.theme.colorscheme) palette;

  cfg = config.my.theme.tokyonight;
  enable = cfg.enable && config.my.gui.enable && isLinux;
in {
  config = mkIf enable {
    wayland.windowManager.hyprland.settings = with palette; {
      group = {
        "col.border_active" = gradient fg 0.4 magenta2 0.9 45;
        "col.border_inactive" = gradient bg 0.5 bg_visual 0.9 45;
        "col.border_locked_active" = gradient red 0.4 teal 0.9 90;
        "col.border_locked_inactive" = gradient yellow 0.5 orange 0.9 90;
        groupbar = {
          text_color = rgba black 1.0;
          "col.active" = rgba todo 1.0;
          "col.inactive" = rgba bg_visual 0.8;
          "col.locked_active" = rgba red 1.0;
          "col.locked_inactive" = rgba orange 0.8;
        };
      };

      general = with palette; {
        "col.inactive_border" = gradient bg_highlight 0.5 bg_dark 0.9 45;
        "col.active_border" = gradient border_highlight 0.4 magenta 0.9 45;
        "col.nogroup_border" = gradient bg 0.8 bg_dark1 1.0 0;
        "col.nogroup_border_active" = gradient fg 0.8 blue 1.0 0;
      };

      decoration = {
        shadow = {
          color = rgba bg_highlight 0.7;
          color_inactive = rgba black 0.9;
        };
      };
    };
  };
}
