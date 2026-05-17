{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.nixporn.colorschemes.catppuccin;
  enable = config.nixporn.colorscheme == "catppuccin" && osConfig.dot.gui.enable && isLinux;
  themeName = "catppuccin-${cfg.flavor}-${cfg.accent}-standard";
in
{
  config = mkIf enable {
    gtk = {
      theme = {
        name = themeName;
        package = pkgs.catppuccin-gtk.override {
          accents = [ cfg.accent ];
          variant = cfg.flavor;
        };
      };
    };
  };
}
