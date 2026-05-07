{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.dot) scanPaths;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.dot.gui) desktop;
  cfg = desktop.niri;
in
{
  imports = [ inputs.niri.homeModules.niri ] ++ scanPaths ./.;
  options.dot.gui.desktop.niri = {
    enable = mkEnableOption "Enable Niri" // {
      default = desktop.wayland.enable && desktop.default == "niri";
      internal = true;
      readOnly = true;
    };
  };
  config = mkIf cfg.enable {
    programs.niri = {
      enable = true;
      settings = {
        gestures.hot-corners.enable = false;
        xwayland-satellite = {
          enable = true;
          path = lib.getExe pkgs.xwayland-satellite;
        };
        prefer-no-csd = true;
        hotkey-overlay = {
          skip-at-startup = true;
          hide-not-bound = false;
        };
      };
    };
  };
}
