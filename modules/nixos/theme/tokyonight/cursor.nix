{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.dot) capitalize;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (config.dot.theme) tokyonight colorscheme;
  cfg = tokyonight;
  enable = cfg.enable && config.dot.gui.enable && isLinux;
  xcursorName = "Bibata-Tokyonight-${capitalize cfg.style}";
  hyprcursorName = "${xcursorName}-Hyprcursor";
  xcursorPackage = pkgs.dot.bibata-xcursor.override {
    cursorThemeName = xcursorName;
    inherit (colorscheme.palette.cursor) baseColor outlineColor watchBackgroundColor;
  };
  hyprcursorPackage = pkgs.dot.bibata-hyprcursor.override {
    cursorThemeName = hyprcursorName;
    inherit (colorscheme.palette.cursor) baseColor outlineColor watchBackgroundColor;
  };
in
{
  config = mkIf enable {
    dot.theme.cursor = {
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
