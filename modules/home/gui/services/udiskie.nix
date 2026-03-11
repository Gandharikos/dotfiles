{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.my) gui;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.my.services.udiskie;
  enable = gui.enable && cfg.enable && isLinux;
in {
  options.my.services.udiskie = {
    enable =
      mkEnableOption "udiskie"
      // {
        default = true;
      };
  };

  config = mkIf enable {
    # auto mount usb drives
    services.udiskie.enable = true;
  };
}
