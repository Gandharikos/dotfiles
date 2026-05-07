{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (config.dot) gui;
  cfg = config.dot.gui.apps.anki;
  enable = gui.enable && cfg.enable && isLinux;
in
{
  options.dot.gui.apps.anki = {
    enable = mkEnableOption "Anki";
  };

  config = mkIf enable {
    home.packages = with pkgs; [
      anki
    ];
  };
}
