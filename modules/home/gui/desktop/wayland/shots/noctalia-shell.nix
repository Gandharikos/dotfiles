{
  lib,
  config,
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
  inherit (config.my.gui) desktop;

  noctaliaEnabled = config.programs.noctalia-shell.enable or false;
  enable =
    desktop.wayland.enable && config.my.gui.desktop.shot.default == "noctalia-shell" && noctaliaEnabled;
  screenToolkitSettingsFile = "${config.home.homeDirectory}/.dotfiles/config/noctalia/plugins/screen-toolkit/settings.json";

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
    # Keep the plugin settings writable so Noctalia can update them,
    # while still sourcing the initial defaults from this repo.
    xdg.configFile."noctalia/plugins/screen-toolkit/settings.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink (toString screenToolkitSettingsFile);
    };

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
