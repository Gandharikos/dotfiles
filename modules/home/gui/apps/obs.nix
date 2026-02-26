{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.desktop.apps.obs;
  # inherit (pkgs.stdenv.hostPlatform) isLinux;
in {
  options.my.desktop.apps.obs = {
    enable =
      mkEnableOption "OBS"
      // {
        default = false;
      };
  };

  config = mkIf cfg.enable {
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

    home.persistence."/persist" = {
      directories = [
        {
          directory = ".config/obs-studio";
          method = "symlink";
        }
      ];
    };
  };
}
