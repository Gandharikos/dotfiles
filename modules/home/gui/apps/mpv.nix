{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (config.my) gui;
  cfg = config.my.gui.apps.mpv;
  enable = gui.enable && cfg.enable;
in {
  options.my.gui.apps.mpv = {
    enable =
      mkEnableOption "support for mpv"
      // {
        default = isLinux;
      };
  };

  config = mkIf enable {
    programs.mpv = {
      enable = true;

      defaultProfiles = ["gpu-hq"];
      scripts = with pkgs.mpvScripts; [
        mpris
        mpvacious
      ];
    };

    services.plex-mpv-shim.enable = true;
  };
}
