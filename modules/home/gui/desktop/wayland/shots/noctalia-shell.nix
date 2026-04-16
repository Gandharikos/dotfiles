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
  inherit (config.my.gui) desktop;

  noctaliaEnabled = config.programs.noctalia-shell.enable or false;
  enable =
    desktop.wayland.enable && config.my.gui.desktop.shot.default == "noctalia-shell" && noctaliaEnabled;

  noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  uwsm = getExe' pkgs.uwsm "uwsm";
  noctaliaExe = getExe' noctaliaPkg "noctalia-shell";
  noctaliaCmd = [
    uwsm
    "app"
    "--"
    noctaliaExe
  ];
  noctaliaIpc =
    args:
    noctaliaCmd
    ++ [
      "ipc"
      "call"
    ]
    ++ args;
  noctaliaScreenshot =
    mode:
    escapeShellArgs (noctaliaIpc [
      "plugin:screenshot"
      "takeScreenshot"
      mode
    ]);
in
{
  config = mkIf enable {

    wayland.windowManager.hyprland.settings.bindd = [
      ", Print, Screenshot Region, exec, ${noctaliaScreenshot "region"}"
      "CTRL, Print, Screenshot Focused Output, exec, ${noctaliaScreenshot "output"}"
      "ALT, Print, Screenshot Focused Window, exec, ${noctaliaScreenshot "window"}"
    ];

    programs.niri.settings.binds = {
      "Print".action.spawn = noctaliaIpc [
        "plugin:screenshot"
        "takeScreenshot"
        "region"
      ];
      "Ctrl+Print".action.spawn = noctaliaIpc [
        "plugin:screenshot"
        "takeScreenshot"
        "output"
      ];
      "Alt+Print".action.spawn = noctaliaIpc [
        "plugin:screenshot"
        "takeScreenshot"
        "window"
      ];
    };
  };
}
