{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.modules) mkIf mkDefault;
  inherit (config.my.gui) desktop;
in {
  config = mkIf desktop.enable {
    services.xserver = {
      enable = mkDefault false;
      desktopManager.xterm.enable = mkDefault false;

      excludePackages = [pkgs.xterm];
    };
  };
}
