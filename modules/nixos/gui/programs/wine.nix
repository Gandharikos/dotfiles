{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.lists) optional;
  inherit (lib.my) isWayland;
  cfg = config.my.desktop.wine;
  isWayland' = isWayland config;
in {
  options.my.desktop.wine = lib.my.mkProgram pkgs "wine" {
    enable.default = config.my.game.enable;
    package.default =
      if isWayland'
      then pkgs.wineWowPackages.waylandFull
      else pkgs.wineWowPackages.stableFull;
  };

  # determine which version of wine to use
  config.environment.systemPackages = optional cfg.enable cfg.package;
}
