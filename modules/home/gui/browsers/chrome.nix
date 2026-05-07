{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.dot) gui;
  cfg = config.dot.gui.apps.chrome;
  enable = gui.enable && cfg.enable;
in
{
  options.dot.gui.apps.chrome = {
    enable = mkEnableOption "chrome" // {
      default = config.dot.gui.browser.default == "google-chrome";
    };
  };

  config = mkIf enable {
    home = {
      packages = with pkgs; [ google-chrome ];
    };
  };
}
