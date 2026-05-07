{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.lists) optional;
  cfg = config.dot.gui.wine;
  waylandEnabled = config.dot.gui.desktop.wayland.enable;
in
{
  options.dot.gui.wine = lib.dot.mkProgram pkgs "wine" {
    enable.default = config.dot.game.enable;
    package.default =
      if waylandEnabled then pkgs.wineWowPackages.waylandFull else pkgs.wineWowPackages.stableFull;
  };

  # determine which version of wine to use
  config.environment.systemPackages = optional cfg.enable cfg.package;
}
