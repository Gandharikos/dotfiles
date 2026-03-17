{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.lists) optional;
  cfg = config.my.gui.system.wine;
  waylandEnabled = config.my.gui.desktop.wayland.enable;
in
{
  options.my.gui.system.wine = lib.my.mkProgram pkgs "wine" {
    enable.default = config.my.game.enable;
    package.default =
      if waylandEnabled then pkgs.wineWowPackages.waylandFull else pkgs.wineWowPackages.stableFull;
  };

  # determine which version of wine to use
  config.environment.systemPackages = optional cfg.enable cfg.package;
}
