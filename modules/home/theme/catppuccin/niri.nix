{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (config.my.theme.colorscheme) palette;
  cfg = config.my.theme.catppuccin;
  enable = cfg.enable && config.my.gui.enable && isLinux && config.my.gui.desktop.niri.enable;
  accent = palette.${cfg.accent};
in
{
  config = mkIf enable {
    programs.niri.settings.layout = {
      background-color = palette.base;
      border = {
        active.color = accent;
        inactive.color = palette.surface0;
        urgent.color = palette.red;
      };
      focus-ring = {
        active.gradient = {
          from = palette.blue;
          to = accent;
          angle = 45;
          in' = "oklch longer hue";
        };
        inactive.color = palette.mantle;
        urgent.color = palette.yellow;
      };
    };
  };
}
