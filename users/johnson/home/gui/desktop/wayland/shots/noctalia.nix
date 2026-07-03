{
  lib,
  config,
  osConfig,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) escapeShellArgs;

  noctaliaEnabled = config.programs.noctalia.enable or false;
  enable =
    osConfig.dot.gui.desktop.wayland.enable
    && config.my.gui.desktop.shot.default == "shell"
    && config.my.gui.desktop.shell.default == "noctalia"
    && noctaliaEnabled;

  noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  noctaliaExe = getExe noctaliaPkg;
  noctaliaMsg =
    args:
    [
      noctaliaExe
      "msg"
    ]
    ++ args;
  noctaliaScreenshot = args: escapeShellArgs (noctaliaMsg args);
in
{
  config = mkIf enable {
    wayland.windowManager.hyprland.settings.bindd = [
      ", Print, Screenshot Region, exec, ${noctaliaScreenshot [ "screenshot-region" ]}"
      "CTRL, Print, Screenshot All Outputs, exec, ${
        noctaliaScreenshot [
          "screenshot-fullscreen"
          "all"
        ]
      }"
      "ALT, Print, Screenshot Pick Output, exec, ${
        noctaliaScreenshot [
          "screenshot-fullscreen"
          "pick"
        ]
      }"
    ];

    programs.niri.settings.binds = {
      "Print".action.spawn = noctaliaMsg [
        "screenshot-region"
      ];
      "Ctrl+Print".action.spawn = noctaliaMsg [
        "screenshot-fullscreen"
        "all"
      ];
      "Alt+Print".action.spawn = noctaliaMsg [
        "screenshot-fullscreen"
        "pick"
      ];
    };
  };
}
