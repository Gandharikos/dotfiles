{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.theme.tokyonight;
in
{
  config = mkIf cfg.enable {
    programs.noctalia-shell.settings.colorSchemes = {
      predefinedScheme = "Tokyo Night";
      useWallpaperColors = false;
    };
  };
}
