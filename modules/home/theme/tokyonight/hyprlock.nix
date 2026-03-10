{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.my) rgba;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (config.my.theme.colorscheme) palette;

  cfg = config.my.theme.tokyonight;
  enable = cfg.enable && config.my.gui.enable && isLinux;
in {
  config = mkIf enable {
    my.gui.desktop.hyprlock.colors = {
      background = rgba palette.bg 0.8;
      input_field = {
        outer = rgba palette.bg 0.8;
        inner = rgba palette.bg_visual 0.8;
        font = rgba palette.fg 1.0;
        placeholder = rgba palette.fg_dark 0.5;
      };
      label = {
        day = rgba palette.blue 0.7;
        month = rgba palette.fg 0.7;
        time = rgba palette.fg 0.7;
        user = rgba palette.fg 0.7;
        power = rgba palette.magenta2 0.7;
      };
      userbox = rgba palette.fg 0.7;
      userbox_border = rgba palette.fg 0.7;
      avatar_border = rgba palette.fg 0.7;
    };
  };
}
