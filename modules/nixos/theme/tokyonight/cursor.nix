{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.my) capitalize;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (config.my.theme) tokyonight colorscheme;
  cfg = tokyonight;
  enable = cfg.enable && config.my.gui.enable && isLinux;
  xcursorName = "Bibata-Tokyonight-${capitalize cfg.style}";
  hyprcursorName = "${xcursorName}-Hyprcursor";
  xcursorPackage = pkgs.my.bibata-xcursor.override {
    cursorThemeName = xcursorName;
    inherit (colorscheme.palette.cursor) baseColor outlineColor watchBackgroundColor;
  };
  hyprcursorPackage = pkgs.my.bibata-hyprcursor.override {
    cursorThemeName = hyprcursorName;
    inherit (colorscheme.palette.cursor) baseColor outlineColor watchBackgroundColor;
  };
in {
  config = mkIf enable {
    my.theme.cursor = {
      name = xcursorName;
      package = xcursorPackage;
      size = 24;
      hyprcursor = {
        name = hyprcursorName;
        package = hyprcursorPackage;
      };
    };
  };
}
