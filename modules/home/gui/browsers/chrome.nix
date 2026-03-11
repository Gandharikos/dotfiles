{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.gui.apps.chrome;
in {
  options.my.gui.apps.chrome = {
    enable =
      mkEnableOption "chrome"
      // {
        default = config.my.gui.browser.default == "google-chrome";
      };
  };

  config = mkIf cfg.enable {
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
