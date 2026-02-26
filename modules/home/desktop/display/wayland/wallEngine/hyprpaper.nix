{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  # inherit (lib.my) isWayland;
  inherit (config.my.theme) wallpaper;
  # enable = config.my.desktop.wallEngine == "hyprpaper" && isWayland config;
  enable = false;
in {
  config = mkIf enable {
    services.hyprpaper = {
      enable = true;

      settings = {
        ipc = "on";
        splash = false;
        splash_offset = 2.0;

        preload = ["${wallpaper}"];
        wallpaper = [", ${wallpaper}"];
      };
    };
  };
}
