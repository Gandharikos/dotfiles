{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.my.gui.apps.anki;
  enable = osConfig.dot.gui.enable && cfg.enable && isLinux;
in
{
  options.my.gui.apps.anki = {
    enable = mkEnableOption "Anki";
  };

  config = mkIf enable {
    home.packages = with pkgs; [
      anki
    ];
  };
}
