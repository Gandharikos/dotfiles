{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.gui.apps.keyguard;
  enable = osConfig.dot.gui.enable && cfg.enable;
in
{
  options.my.gui.apps.keyguard = {
    enable = mkEnableOption "Keyguard" // {
      default = false;
    };
  };

  config = mkIf enable {
    home.packages = with pkgs; [
      keyguard
    ];
  };
}
