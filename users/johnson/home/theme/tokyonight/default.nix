{
  inputs,
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib.dot) capitalize;
  inherit (lib.modules) mkDefault mkIf mkMerge;
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  cfg = config.nixporn.colorschemes.tokyonight;
  cursorEnable = config.nixporn.colorscheme == "tokyonight" && osConfig.dot.gui.enable && isLinux;
  hyprlandEnabled = config.my.gui.desktop.hyprland.enable;
  bibata = config.nixporn.cursors.bibata;

  xcursorName = "Bibata-Tokyonight-${capitalize cfg.style}";
  hyprcursorName = "${xcursorName}-Hyprcursor";

  xcursorPackage = pkgs.dot.bibata-xcursor.override {
    cursorThemeName = xcursorName;
    inherit (bibata) baseColor outlineColor watchBackgroundColor;
  };

  hyprcursorPackage = pkgs.dot.bibata-hyprcursor.override {
    cursorThemeName = hyprcursorName;
    inherit (bibata) baseColor outlineColor watchBackgroundColor;
  };

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
    moon = inputs.wallpapers.tokyonight.tokyo-night-street.path;
    night = inputs.wallpapers.tokyonight.tokyo-night-street-main.path;
    storm = inputs.wallpapers.tokyonight.tokyo-night-street-rain.path;
  };
in
{
  imports = lib.dot.scanPaths ./.;

  config = mkMerge [
    (mkIf (config.nixporn.colorscheme == "tokyonight") {
      nixporn = {
        avatar = mkDefault osConfig.nixporn.avatar;
        wallpaper = mkDefault tokyonightWallpaper.${cfg.style};
        cursors.bibata = mkDefault (tokyonightCursor cfg.palette).${cfg.style};
      };

      home.sessionVariables.COLORSCHEME_STYLE = cfg.style;
    })
    (mkIf cursorEnable (mkMerge [
      {
        home.pointerCursor = {
          name = xcursorName;
          package = xcursorPackage;
          size = 24;
          gtk.enable = true;
          x11.enable = true;
        };
      }
      (mkIf hyprlandEnabled {
        home = {
          packages = [ hyprcursorPackage ];
          sessionVariables = {
            HYPRCURSOR_THEME = hyprcursorName;
            HYPRCURSOR_SIZE = "24";
          };
        };
      })
    ]))
  ];
}
