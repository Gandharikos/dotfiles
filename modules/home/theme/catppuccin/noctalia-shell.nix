{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.theme.catppuccin;
in
{
  config = mkIf cfg.enable {
    programs.noctalia-shell.settings.colorSchemes = {
      predefinedScheme = "Catppuccin";
      useWallpaperColors = false;
    };
  };
}
