{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (config.my) gui;
  cfg = config.my.gui.apps.obs;
  enable = gui.enable && cfg.enable;
  # inherit (pkgs.stdenv.hostPlatform) isLinux;
in
{
  options.my.gui.apps.obs = {
    enable = mkEnableOption "OBS" // {
      default = false;
    };
  };

  config = mkIf enable {
    programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        looking-glass-obs
        obs-livesplit-one
        obs-pipewire-audio-capture
        obs-gstreamer
        obs-move-transition
        obs-multi-rtmp
        obs-vkcapture
        input-overlay
        wlrobs
      ];
    };
  };
}
