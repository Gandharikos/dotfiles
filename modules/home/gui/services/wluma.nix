{
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.my.services.wluma;
  enable = osConfig.dot.gui.enable && cfg.enable && isLinux;
in
{
  options.my.services.wluma = {
    enable = mkEnableOption "wluma" // {
      default = true;
    };
  };

  config = mkIf enable {
    # auto adjust the brightness of your screen based on the time of day
    services.wluma.enable = true;
  };
}
