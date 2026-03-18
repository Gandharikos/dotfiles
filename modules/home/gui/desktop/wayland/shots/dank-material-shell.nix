{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib.meta) getExe';
  inherit (lib.modules) mkIf;
  inherit (lib.strings) escapeShellArgs;
  inherit (lib.my) uwsmAppArgs;
  inherit (config.my.gui) desktop;

  dmsEnabled = config.programs.dank-material-shell.enable or false;
  enable =
    desktop.wayland.enable && config.my.gui.desktop.shot.default == "dank-material-shell" && dmsEnabled;

  dmsPkg = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
  dmsExe = getExe' dmsPkg "dms";
  dmsCmd = if desktop.uwsm.enable then uwsmAppArgs pkgs dmsExe [ ] else [ dmsExe ];
  dms =
    args:
    dmsCmd
    ++ [
      "screenshot"
    ]
    ++ args;
  dmsIpc =
    args:
    dmsCmd
    ++ [
      "ipc"
      "call"
    ]
    ++ args;
  dmsScreenshot = args: escapeShellArgs (dms args);
in
{
  config = mkIf enable {
    wayland.windowManager.hyprland.settings.bindd = [
      ", Print, Screenshot Region, exec, ${dmsScreenshot [ ]}"
      "SHIFT, Print, Screenshot Last Region, exec, ${dmsScreenshot [ "last" ]}"
      "CTRL, Print, Screenshot Focused Output, exec, ${dmsScreenshot [ "full" ]}"
      "ALT, Print, Screenshot All Outputs, exec, ${dmsScreenshot [ "all" ]}"
    ];

    home.sessionVariables.DMS_SCREENSHOT_EDITOR = "satty";
    programs.niri.settings.binds = {
      "Print".action.spawn = dmsIpc [
        "niri"
        "screenshot"
      ];
      "Shift+Print".action.spawn = dms [ ];
      "Ctrl+Print".action.spawn = dmsIpc [
        "niri"
        "screenshotScreen"
      ];
      "Alt+Print".action.spawn = dmsIpc [
        "niri"
        "screenshotWindow"
      ];
    };
  };
}
