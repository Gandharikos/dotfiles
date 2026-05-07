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
  cfg = config.my.theme.catppuccin;
  dmsEnabled = config.programs.dank-material-shell.enable or false;
  accent = palette.${cfg.accent};
  theme = {
    primary = accent;
    primaryText = palette.base;
    primaryContainer = palette.teal;
    secondary = palette.peach;
    surface = palette.mantle;
    surfaceText = palette.text;
    surfaceVariant = palette.surface0;
    surfaceVariantText = palette.subtext1;
    surfaceTint = accent;
    background = palette.base;
    backgroundText = palette.text;
    outline = palette.surface2;
    surfaceContainer = palette.mantle;
    surfaceContainerHigh = palette.surface0;
    surfaceContainerHighest = palette.surface2;
    error = palette.red;
    warning = palette.peach;
    info = palette.blue;
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
