{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe;
  inherit (lib.my) uwsmScript uwsmScriptArgs;
  enable = config.my.gui.desktop.shot.default == "hyprshot" && config.my.gui.desktop.wayland.enable;
  hyprshot = getExe pkgs.hyprshot;
  satty = getExe pkgs.satty;
  regionShot = uwsmScript pkgs "hyprshot-region-shot" ''
    ${hyprshot} --mode region --raw | ${satty} --filename -
  '';
  windowShot = uwsmScript pkgs "hyprshot-window-shot" ''
    ${hyprshot} --mode window --raw | ${satty} --filename -
  '';
  outputShot = uwsmScript pkgs "hyprshot-output-shot" ''
    ${hyprshot} --mode output --raw | ${satty} --filename -
  '';
  regionShotArgs = uwsmScriptArgs pkgs "hyprshot-region-shot" ''
    ${hyprshot} --mode region --raw | ${satty} --filename -
  '';
  windowShotArgs = uwsmScriptArgs pkgs "hyprshot-window-shot" ''
    ${hyprshot} --mode window --raw | ${satty} --filename -
  '';
  outputShotArgs = uwsmScriptArgs pkgs "hyprshot-output-shot" ''
    ${hyprshot} --mode output --raw | ${satty} --filename -
  '';
in {
  config = mkIf enable {
    wayland.windowManager.hyprland.settings.bindd = [
      # region
      ", Print, Screenshot Region, exec, ${regionShot}"

      # current window
      "SHIFT, Print, Screenshot Window, exec, ${windowShot}"

      # current screen
      "CTRL, Print, Screenshot Output, exec, ${outputShot}"
    ];

    programs.niri.settings = {
      binds = {
        "Print".action.spawn = regionShotArgs;
        "Shift+Print".action.spawn = windowShotArgs;
        "Ctrl+Print".action.spawn = outputShotArgs;
      };
    };
  };
}
