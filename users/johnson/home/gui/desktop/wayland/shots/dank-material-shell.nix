{
  lib,
  config,
  osConfig,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib.meta) getExe';
  inherit (lib.modules) mkIf;
  inherit (lib.dot) uwsmAppArgs;

  dmsEnabled = config.programs.dank-material-shell.enable or false;
  enable =
    osConfig.dot.gui.desktop.wayland.enable
    && config.my.gui.desktop.shot.default == "shell"
    && config.my.gui.desktop.shell.default == "dank-material-shell"
    && dmsEnabled;

  dmsPkg = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
  dmsExe = getExe' dmsPkg "dms";
  dmsCmd = if osConfig.dot.gui.desktop.uwsm.enable then uwsmAppArgs pkgs dmsExe [ ] else [ dmsExe ];
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
in
{
  config = mkIf enable {
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
