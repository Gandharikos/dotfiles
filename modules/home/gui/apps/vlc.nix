{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (config.dot) gui;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.dot.gui.apps.vlc;
  enable = gui.enable && cfg.enable;
in
{
  options.dot.gui.apps.vlc = {
    enable = mkEnableOption "VLC" // {
      default = isLinux;
    };
  };

  config = mkIf enable {
    home = {
      packages = with pkgs; [ vlc ];
    };
  };
}
