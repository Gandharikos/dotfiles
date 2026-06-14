{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (osConfig.dot.device) monitors;
  hasHidpi = builtins.any (m: (m.scale or 1.0) > 1.0) monitors;
  dpi = if hasHidpi then 192 else 96;
  isXorg = osConfig.dot.gui.desktop.xorg.enable or false;
  enable = isLinux && isXorg;
in
{
  config = mkIf enable {
    xresources.properties = {
      "*.faceName" = "JetBrainsMono Nerd Font Mono";
      "*.faceSize" = toString 14;
      "*.renderFont" = true;
      "Xft.dpi" = dpi;
      "*.dpi" = dpi;

      "Xft.autohint" = 0;
      "Xft.lcdfilter" = "lcddefault";
      "Xft.hintstyle" = "hintfull";
      "Xft.antialias" = 1;
      "Xft.rgba" = "rgb";
    };
  };
}
