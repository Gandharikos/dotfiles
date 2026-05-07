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
  cfg = config.my.gui.apps.vlc;
  enable = osConfig.dot.gui.enable && cfg.enable;
in
{
  options.my.gui.apps.vlc = {
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
