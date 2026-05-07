{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (config.my.theme.colorscheme) palette;

  cfg = config.my.theme.tokyonight;
  enable = cfg.enable && osConfig.dot.gui.enable && isLinux;
in
{
  config = mkIf enable {
    programs.niri.settings.layout = {
      background-color = palette.bg;
      border = {
        active.color = palette.magenta;
        inactive.color = palette.bg_highlight;
        urgent.color = palette.red;
      };
      focus-ring = {
        active.gradient = {
          from = palette.blue;
          to = palette.magenta;
          angle = 45;
          in' = "oklch longer hue";
        };
        inactive.color = palette.bg_dark;
        urgent.color = palette.yellow;
      };
    };
  };
}
