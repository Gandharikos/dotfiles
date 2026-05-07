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
  cfg = config.dot.services.udiskie;
  enable = gui.enable && cfg.enable && isLinux;
in
{
  options.dot.services.udiskie = {
    enable = mkEnableOption "udiskie" // {
      default = true;
    };
  };

  config = mkIf enable {
    # auto mount usb drives
    services.udiskie.enable = true;
  };
}
