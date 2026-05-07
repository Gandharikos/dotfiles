{
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.my.theme.colorscheme) palette;
  cfg = config.my.theme.catppuccin;
  accent = palette.${cfg.accent};
in
{
  config = mkIf cfg.enable {
    programs.noctalia-shell = {
      colors = {
        mPrimary = accent;
        mOnPrimary = palette.base;
        mSecondary = palette.peach;
        mOnSecondary = palette.base;
        mTertiary = palette.teal;
        mOnTertiary = palette.base;
        mError = palette.red;
        mOnError = palette.base;
        mSurface = palette.base;
        mOnSurface = palette.text;
        mHover = palette.teal;
        mOnHover = palette.base;
        mSurfaceVariant = palette.surface0;
        mOnSurfaceVariant = palette.subtext1;
        mOutline = palette.surface2;
        mShadow = palette.crust;
      };

      settings.colorSchemes = {
        darkMode = cfg.flavor != "latte";
        predefinedScheme = "";
        useWallpaperColors = false;
      };
    };
  };
}
