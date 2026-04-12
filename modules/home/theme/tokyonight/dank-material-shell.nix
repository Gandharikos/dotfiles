{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.theme.tokyonight;
  dmsEnabled = config.programs.dank-material-shell.enable or false;
in
{
  config = mkIf (cfg.enable && dmsEnabled) {
    programs.dank-material-shell.settings = {
      customThemeFile = "/home/johnson/.config/DankMaterialShell/themes/tokyoNightNightMoon/theme.json";
    };
  };
}
