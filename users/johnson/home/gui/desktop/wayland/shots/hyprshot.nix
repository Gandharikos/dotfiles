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
    config.my.gui.desktop.shot.default == "hyprshot" && osConfig.dot.gui.desktop.wayland.enable;
  hyprshot = getExe pkgs.hyprshot;
  satty = getExe pkgs.satty;
  regionShotArgs = uwsmScriptArgs pkgs "hyprshot-region-shot" ''
    ${hyprshot} --mode region --raw | ${satty} --filename -
  '';
  windowShotArgs = uwsmScriptArgs pkgs "hyprshot-window-shot" ''
    ${hyprshot} --mode window --raw | ${satty} --filename -
  '';
  outputShotArgs = uwsmScriptArgs pkgs "hyprshot-output-shot" ''
    ${hyprshot} --mode output --raw | ${satty} --filename -
  '';
in
{
  config = mkIf enable {
    programs.niri.settings = {
      binds = {
        "Print".action.spawn = regionShotArgs;
        "Shift+Print".action.spawn = windowShotArgs;
        "Ctrl+Print".action.spawn = outputShotArgs;
      };
    };
  };
}
