{
  inputs,
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkDefault mkIf mkMerge;
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  cfg = config.nixporn.colorschemes.tokyonight;
  enable = config.nixporn.colorscheme == "tokyonight" && osConfig.dot.gui.enable && isLinux;

  tokyonightCursor = palette: {
    day = {
      baseColor = palette.magenta2;
      outlineColor = palette.bg_highlight;
      watchBackgroundColor = palette.bg_search;
    };
    moon = {
      baseColor = palette.magenta2;
      outlineColor = palette.bg_highlight;
      watchBackgroundColor = palette.orange;
    };
    night = {
      baseColor = palette.blue;
      outlineColor = palette.bg_highlight;
      watchBackgroundColor = palette.info;
    };
    storm = {
      baseColor = palette.teal;
      outlineColor = palette.bg_highlight;
      watchBackgroundColor = palette.purple;
    };
  };

  tokyonightWallpaper = {
    day = inputs.wallpapers.tokyonight.japan-city-river.path;
    moon = inputs.wallpapers.tokyonight.night-japan-street-dark.path;
    night = inputs.wallpapers.tokyonight.tokyo-night-street-main.path;
    storm = inputs.wallpapers.tokyonight.tokyo-night-street-rain.path;
  };
in
{
  imports = lib.dot.scanPaths ./.;

  config = mkMerge [
    (mkIf (config.nixporn.colorscheme == "tokyonight") {
      home.sessionVariables.COLORSCHEME_STYLE = cfg.style;
    })
    (mkIf enable {
      nixporn = {
        avatar = mkDefault osConfig.nixporn.avatar;
        wallpaper = mkDefault tokyonightWallpaper.${cfg.style};
        cursors.bibata = mkDefault (tokyonightCursor cfg.palette).${cfg.style};
      };

      home.pointerCursor = {
        enable = true;
        size = 24;
        gtk.enable = true;
        x11.enable = true;
      };

      home.sessionVariables.HYPRCURSOR_SIZE = "24";
    })
  ];
}
