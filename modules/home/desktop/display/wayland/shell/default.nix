{
  inputs,
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.my) isWayland;
  enable = config.my.desktop.polkit == "hyprpolkit" && isWayland config;
in {
  imports = [
    inputs.dms.homeModules.dank-material-shell
  ];
  config = mkIf enable {
    programs.dank-material-shell = {
      enable = true;

      systemd = {
        enable = true;
        restartIfChanged = true;
      };

      enableSystemMonitoring = true; # System monitoring widgets (dgop)
      enableDynamicTheming = true; # Wallpaper-based theming (matugen)
      enableVPN = true; # VPN management widget
      enableAudioWavelength = true; # Audio visualizer (cava)
      enableCalendarEvents = true; # Calendar integration (khal)
    };
  };
}
