{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.dot.theme.colorscheme) palette;
  cfg = config.dot.theme.tokyonight;
in
{
  config = mkIf cfg.enable {
    programs.noctalia-shell = {
      colors = {
        mPrimary = palette.blue;
        mOnPrimary = palette.bg;
        mSecondary = palette.magenta;
        mOnSecondary = palette.bg;
        mTertiary = palette.green;
        mOnTertiary = palette.bg;
        mError = palette.red;
        mOnError = palette.bg;
        mSurface = palette.bg;
        mOnSurface = palette.fg;
        mHover = palette.cyan;
        mOnHover = palette.bg;
        mSurfaceVariant = palette.bg_highlight;
        mOnSurfaceVariant = palette.fg_dark;
        mOutline = palette.fg_gutter;
        mShadow = palette.black;
      };

      settings.colorSchemes = {
        darkMode = cfg.style != "day";
        predefinedScheme = "";
        useWallpaperColors = false;
      };
    };
  };
}
