{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe;
  inherit (lib.my) runOnce;
  grimblast' = runOnce pkgs "grimblast";
  satty' = runOnce pkgs "satty";
  enable = config.my.gui.desktop.shot == "grimblast" && config.my.gui.desktop.wayland.enable;
  cfgNiri = config.my.gui.desktop.niri;
  bash = getExe pkgs.bash;
  grimblast = getExe pkgs.grimblast;
  satty = getExe pkgs.satty;
  niriSpawn = command: {action.spawn = [bash "-lc" command];};
in {
  config = mkIf enable {
    wayland.windowManager.hyprland.settings = {
      bindd = [
        # region
        ", Print, Screenshot Region, exec, ${grimblast'} --notify copysave area - | ${satty'} --filename -"

        # current window
        "SHIFT, Print, Screenshot Window, exec, ${grimblast'} --notify copysave active - | ${satty'} --filename -"

        # current screen
        "CTRL, Print, Screenshot Output, exec, ${grimblast'} --notify --cursor copysave output - | ${satty'} --filename -"

        # all screens
        "ALT, Print, Screenshot All Screens, exec, ${grimblast'} --notify --cursor copysave screen - | ${satty'} --filename -"
      ];
      env = [
        # can fix high cpu loads on some machines
        "GRIMBLAST_HIDE_CURSOR,0"
        # See https://github.com/hyprwm/contrib/issues/142
        "GRIMBLAST_NO_CURSOR,0"
      ];
    };

    programs.niri.settings = mkIf cfgNiri.enable {
      environment = {
        GRIMBLAST_HIDE_CURSOR = "0";
        GRIMBLAST_NO_CURSOR = "0";
      };
      binds = {
        "Print" = niriSpawn "${grimblast} --notify copysave area - | ${satty} --filename -";
        "Shift+Print" = niriSpawn "${grimblast} --notify copysave active - | ${satty} --filename -";
        "Ctrl+Print" = niriSpawn "${grimblast} --notify --cursor copysave output - | ${satty} --filename -";
        "Alt+Print" = niriSpawn "${grimblast} --notify --cursor copysave screen - | ${satty} --filename -";
      };
    };
  };
}
