{
  pkgs,
  config,
  osConfig,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.gui.apps.chrome;
  enable = osConfig.dot.gui.enable && cfg.enable;
in
{
  options.my.gui.apps.chrome = {
    enable = mkEnableOption "chrome" // {
      default = config.my.gui.browser.default == "google-chrome";
    };
  };

  config = mkIf enable {
    home = {
      packages = [ pkgs.google-chrome ];
    };
  };
}
