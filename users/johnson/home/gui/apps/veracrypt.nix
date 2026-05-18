{
  pkgs,
  config,
  osConfig,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.my.gui.apps.veracrypt;
  enable = osConfig.dot.gui.enable && cfg.enable;
in
{
  options.my.gui.apps.veracrypt = {
    enable = mkEnableOption "Veracrypt" // {
      default = isLinux;
    };
  };

  config = mkIf enable {
    home.packages = with pkgs; [
      veracrypt # a free disk encryption software
    ];
  };
}
