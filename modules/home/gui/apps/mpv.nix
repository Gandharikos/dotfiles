{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (lib.lists) optionals;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.my.gui.apps.mpv;
in {
  options.my.gui.apps.mpv = {
    enable =
      mkEnableOption "support for mpv"
      // {
        default = config.my.gui.enable;
      };
  };

  config = mkIf cfg.enable {
    programs.mpv = {
      enable = isLinux;
      package = pkgs.mpv;

      defaultProfiles = ["gpu-hq"];
      scripts = optionals isLinux (with pkgs.mpvScripts; [
        mpris
        mpvacious
      ]);
    };

    services.plex-mpv-shim.enable = isLinux;
  };
}
