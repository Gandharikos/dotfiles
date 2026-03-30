{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.my.theme.catppuccin;
  enable = cfg.enable && config.my.gui.enable && isLinux;
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
