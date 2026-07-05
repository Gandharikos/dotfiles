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
  inherit (lib.dot) uwsmScriptArgs;
  enable =
    config.my.gui.desktop.shot.default == "grimblast" && osConfig.dot.gui.desktop.wayland.enable;
  grimblast = getExe pkgs.grimblast;
  satty = getExe pkgs.satty;
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
