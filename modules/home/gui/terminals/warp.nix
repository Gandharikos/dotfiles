{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.dot) gui;
  cfg = config.dot.gui.apps.warp;
  enable = gui.enable && cfg.enable;
in
{
  options.dot.gui.apps.warp = {
    enable = mkEnableOption "warp" // {
      default = config.dot.gui.terminal.default == "warp";
    };
  };

  config = mkIf enable {
    home.packages = with pkgs; [ warp-terminal ];
  };
}
