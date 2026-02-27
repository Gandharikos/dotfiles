{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.desktop.apps.chrome;
in {
  options.my.desktop.apps.chrome = {
    enable =
      mkEnableOption "chrome"
      // {
        default = config.my.browser.default == "google-chrome";
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
