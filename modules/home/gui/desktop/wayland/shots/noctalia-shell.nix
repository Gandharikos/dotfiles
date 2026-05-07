{
  lib,
  config,
  osConfig,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib.meta)
    getExe'
    ;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) escapeShellArgs;

  noctaliaEnabled = config.programs.noctalia-shell.enable or false;
  enable =
    osConfig.dot.gui.desktop.wayland.enable
    && config.my.gui.desktop.shot.default == "noctalia-shell"
    && noctaliaEnabled;
  screenshotPath = config.xdg.userDirs.extraConfig.SCREENSHOTS;
  screenToolkitSettingsFile = lib.dot.relativeToConfig "noctalia/plugins/screen-toolkit/settings.json";
  screenToolkitSettings = (builtins.fromJSON (builtins.readFile screenToolkitSettingsFile)) // {
    inherit screenshotPath;
  };

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
      "plugin:screen-toolkit"
      mode
    ]);
in
{
  config = mkIf enable {
    programs.noctalia-shell.pluginSettings."screen-toolkit" = screenToolkitSettings;

    wayland.windowManager.hyprland.settings.bindd = [
      ", Print, Screenshot Region, exec, ${noctaliaScreenshot "annotate"}"
      "CTRL, Print, Screenshot Fullscreen, exec, ${noctaliaScreenshot "annotateFullscreen"}"
      "ALT, Print, Screenshot Focused Window, exec, ${noctaliaScreenshot "annotateWindow"}"
    ];

    programs.niri.settings.binds = {
      "Print".action.spawn = noctaliaIpc [
        "plugin:screen-toolkit"
        "annotate"
      ];
      "Ctrl+Print".action.spawn = noctaliaIpc [
        "plugin:screen-toolkit"
        "annotateFullscreen"
      ];
      "Alt+Print".action.spawn = noctaliaIpc [
        "plugin:screen-toolkit"
        "annotateWindow"
      ];
    };
  };
}
