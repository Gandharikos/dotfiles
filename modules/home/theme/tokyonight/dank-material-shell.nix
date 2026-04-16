{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.my.theme.colorscheme)
    slug
    palette
    ;
  cfg = config.my.theme.tokyonight;
  dmsEnabled = config.programs.dank-material-shell.enable or false;
  theme = {
    primary = palette.blue;
    primaryText = palette.bg;
    primaryContainer = palette.cyan;
    secondary = palette.magenta;
    surface = palette.bg;
    surfaceText = palette.fg;
    surfaceVariant = palette.bg_highlight;
    surfaceVariantText = palette.fg_dark;
    surfaceTint = palette.blue;
    background = palette.bg_dark;
    backgroundText = palette.fg;
    outline = palette.fg_gutter;
    surfaceContainer = palette.bg;
    surfaceContainerHigh = palette.bg_highlight;
    surfaceContainerHighest = palette.bright_black;
    error = palette.red;
    warning = palette.orange;
    info = palette.cyan;
  };
in
{
  config = mkIf (cfg.enable && dmsEnabled) {
    programs.dank-material-shell.settings = {
      currentThemeName = "custom";
      customThemeFile = pkgs.writeText "dank-material-shell-${slug}-theme.json" (
        builtins.toJSON {
          dark = theme;
          light = theme;
        }
      );
    };
  };
}
