{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.lists) optional;
  inherit (lib.modules) mkIf;
  inherit (config.dot) gui;
  cfg = config.dot.gui.wine;
  waylandEnabled = config.dot.gui.desktop.wayland.enable;
in
{
  options.dot.gui.wine = lib.dot.mkProgram pkgs "wine" {
    enable.default = gui.enable && config.dot.gui.game.enable;
    package.default =
      if waylandEnabled then pkgs.wineWow64Packages.waylandFull else pkgs.wineWow64Packages.stableFull;
  };

  # determine which version of wine to use
  config = mkIf gui.enable {
    environment.systemPackages = optional cfg.enable cfg.package;
  };
}
