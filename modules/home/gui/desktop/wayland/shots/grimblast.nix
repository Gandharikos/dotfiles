{
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe;
  inherit (lib.dot) uwsmScript uwsmScriptArgs;
  enable =
    config.my.gui.desktop.shot.default == "grimblast" && osConfig.dot.gui.desktop.wayland.enable;
  grimblast = getExe pkgs.grimblast;
  satty = getExe pkgs.satty;
  areaShot = uwsmScript pkgs "grimblast-area-shot" ''
    ${grimblast} --notify copysave area - | ${satty} --filename -
  '';
  activeShot = uwsmScript pkgs "grimblast-active-shot" ''
    ${grimblast} --notify copysave active - | ${satty} --filename -
  '';
  outputShot = uwsmScript pkgs "grimblast-output-shot" ''
    ${grimblast} --notify --cursor copysave output - | ${satty} --filename -
  '';
  screenShot = uwsmScript pkgs "grimblast-screen-shot" ''
    ${grimblast} --notify --cursor copysave screen - | ${satty} --filename -
  '';
  areaShotArgs = uwsmScriptArgs pkgs "grimblast-area-shot" ''
    ${grimblast} --notify copysave area - | ${satty} --filename -
  '';
  activeShotArgs = uwsmScriptArgs pkgs "grimblast-active-shot" ''
    ${grimblast} --notify copysave active - | ${satty} --filename -
  '';
  outputShotArgs = uwsmScriptArgs pkgs "grimblast-output-shot" ''
    ${grimblast} --notify --cursor copysave output - | ${satty} --filename -
  '';
  screenShotArgs = uwsmScriptArgs pkgs "grimblast-screen-shot" ''
    ${grimblast} --notify --cursor copysave screen - | ${satty} --filename -
  '';
in
{
  config = mkIf enable {
    wayland.windowManager.hyprland.settings = {
      bindd = [
        # region
        ", Print, Screenshot Region, exec, ${areaShot}"

        # current window
        "SHIFT, Print, Screenshot Window, exec, ${activeShot}"

        # current screen
        "CTRL, Print, Screenshot Output, exec, ${outputShot}"

        # all screens
        "ALT, Print, Screenshot All Screens, exec, ${screenShot}"
      ];
      env = [
        # can fix high cpu loads on some machines
        "GRIMBLAST_HIDE_CURSOR,0"
        # See https://github.com/hyprwm/contrib/issues/142
        "GRIMBLAST_NO_CURSOR,0"
      ];
    };

    programs.niri.settings = {
      environment = {
        GRIMBLAST_HIDE_CURSOR = "0";
        GRIMBLAST_NO_CURSOR = "0";
      };
      binds = {
        "Print".action.spawn = areaShotArgs;
        "Shift+Print".action.spawn = activeShotArgs;
        "Ctrl+Print".action.spawn = outputShotArgs;
        "Alt+Print".action.spawn = screenShotArgs;
      };
    };
  };
}
