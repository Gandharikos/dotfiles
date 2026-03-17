{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf mkDefault;
  inherit (config.my) gui;
in
{
  config = mkIf gui.enable {
    services.xserver = {
      enable = mkDefault false;
      desktopManager.xterm.enable = mkDefault false;

      excludePackages = [ pkgs.xterm ];
    };
  };
}
