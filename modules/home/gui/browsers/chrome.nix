{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.my) gui;
  cfg = config.my.gui.apps.chrome;
  enable = gui.enable && cfg.enable;
in {
  options.my.gui.apps.chrome = {
    enable =
      mkEnableOption "chrome"
      // {
        default = config.my.gui.browser.default == "google-chrome";
      };
  };

  config = mkIf enable {
    home = {
      packages = with pkgs; [google-chrome];

      persistence = {
        "/persist".directories = [
          ".config/google-chrome"
          ".cache/google-chrome"
        ];
      };
    };
  };
}
