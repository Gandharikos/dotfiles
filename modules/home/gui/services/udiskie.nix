{
  lib,
  config,
  osClass,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.my.gui) desktop;
  cfg = config.my.services.udiskie;
in {
  options.my.services.udiskie = {
    enable =
      mkEnableOption "udiskie"
      // {
        default =
          if osClass == "nixos"
          then desktop.enable
          else false;
      };
  };

  config = mkIf cfg.enable {
    # auto mount usb drives
    services.udiskie.enable = true;
  };
}
