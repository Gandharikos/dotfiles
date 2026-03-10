{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.my) capitalize;
  inherit (lib.modules) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (config.my.theme) default tokyonight colorscheme;
  inherit (colorscheme) palette;
  cfg = tokyonight;
  colorName = "${capitalize default}-${capitalize cfg.style}";
  enable = cfg.enable && config.my.gui.enable && isLinux;
  variant = "modern";
  cursorName = "Bibata-${capitalize variant}-${colorName}-Hyprcursor";
  cursorPackage = pkgs.my.bibata-hyprcursor.override {
    inherit (palette.cursor) baseColor outlineColor watchBackgroundColor;
    inherit variant colorName;
  };
in {
  config = mkIf enable {
    my.theme.cursor = {
      name = cursorName;
      package = cursorPackage;
      size = 24;
    };
  };
}
