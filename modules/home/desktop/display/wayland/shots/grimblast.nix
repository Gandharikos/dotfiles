{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.my) runOnce isWayland;
  grimblast' = runOnce pkgs "grimblast";
  satty' = runOnce pkgs "satty";
  enable = config.my.desktop.shot == "grimblast" && isWayland config;
in {
  config = mkIf enable {
    # packages = with pkgs; [
    #   grimblast # screenshot grabber
    # ];
    wayland.windowManager.hyprland = {
      settings = {
        bindd = [
          # region
          ", Print, Screenshot Region, exec, ${grimblast'} --notify copysave area - | ${satty'} --filename -"
          "$mod, K, Screenshot Region, exec, ${grimblast'} --notify copysave area - | ${satty'} --filename -"

          # current window
          "SHIFT, Print, Screenshot Window, exec, ${grimblast'} --notify copysave active - | ${satty'} --filename -"
          "$mod SHIFT, K, Screenshot Window, exec, ${grimblast'} --notify copysave active - | ${satty'} --filename -"

          # current screen
          "CTRL, Print, Screenshot Output, exec, ${grimblast'} --notify --cursor copysave output - | ${satty'} --filename -"
          "$mod CTRL, K, Screenshot Output, exec, ${grimblast'} --notify --cursor copysave output - | ${satty'} --filename -"

          # all screens
          "ALT, Print, Screenshot All Screens, exec, ${grimblast'} --notify --cursor copysave screen - | ${satty'} --filename -"
          "$mod ALT, K, Screenshot All Screens, exec, ${grimblast'} --notify --cursor copysave screen - | ${satty'} --filename -"
        ];
        env = [
          # can fix high cpu loads on some machines
          "GRIMBLAST_HIDE_CURSOR,0"
          # See https://github.com/hyprwm/contrib/issues/142
          "GRIMBLAST_NO_CURSOR,0"
        ];
      };
    };
  };
}
