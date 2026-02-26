{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.my.desktop.apps.veracrypt;
in {
  options.my.desktop.apps.veracrypt = {
    enable =
      mkEnableOption "Veracrypt"
      // {
        default = config.my.desktop.enable && isLinux;
      };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      veracrypt # a free disk encryption software
    ];
  };
}
