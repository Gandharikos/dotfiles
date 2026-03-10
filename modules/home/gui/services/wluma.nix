{
  lib,
  config,
  osClass,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.my.gui) desktop;
  cfg = config.my.services.wluma;
in {
  options.my.services.wluma = {
    enable =
      mkEnableOption "wluma"
      // {
        default =
          if osClass == "nixos"
          then desktop.enable
          else false;
      };
  };

  config = mkIf cfg.enable {
    # auto adjust the brightness of your screen based on the time of day
    services.wluma.enable = true;
  };
}
