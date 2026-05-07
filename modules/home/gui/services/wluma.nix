{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.dot) gui;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.dot.services.wluma;
  enable = gui.enable && cfg.enable && isLinux;
in
{
  options.dot.services.wluma = {
    enable = mkEnableOption "wluma" // {
      default = true;
    };
  };

  config = mkIf enable {
    # auto adjust the brightness of your screen based on the time of day
    services.wluma.enable = true;
  };
}
