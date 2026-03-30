{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  enable = config.my.gui.enable && isLinux;
in
{
  config = mkIf enable {
    gtk = {
      enable = true;
      gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";

      font = {
        name = "SFProDisplay Nerd Font";
        size = 13;
      };
    };
  };
}
