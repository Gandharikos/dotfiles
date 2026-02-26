{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe;
  inherit (lib.my) runOnce isWayland;
  hyprshot' = runOnce pkgs "hyprshot";
  satty' = runOnce pkgs "satty";
  enable = config.my.desktop.shot == "hyprshot" && isWayland config;
  uwsm = getExe pkgs.uwsm;
  bash = getExe pkgs.bash;
  hyprshot = getExe pkgs.hyprshot;
  satty = getExe pkgs.satty;
  niriSpawn = command: {action.spawn = [uwsm "app" "--" bash "-lc" command];};
in {
  config = mkIf enable {
    wayland.windowManager.hyprland.settings.bindd = [
      # region
      ", Print, Screenshot Region, exec, ${hyprshot'} --mode region --raw | ${satty'} --filename -"

      # current window
      "SHIFT, Print, Screenshot Window, exec, ${hyprshot'} --mode window --raw | ${satty'} --filename -"

      # current screen
      "CTRL, Print, Screenshot Output, exec, ${hyprshot'} --mode output --raw | ${satty'} --filename -"
    ];

    programs.niri.settings.binds = {
      "Print" = niriSpawn "${hyprshot} --mode region --raw | ${satty} --filename -";
      "Shift+Print" = niriSpawn "${hyprshot} --mode window --raw | ${satty} --filename -";
      "Ctrl+Print" = niriSpawn "${hyprshot} --mode output --raw | ${satty} --filename -";
    };
  };
}
