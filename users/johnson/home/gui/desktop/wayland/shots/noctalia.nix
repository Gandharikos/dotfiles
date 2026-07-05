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
in
{
  config = mkIf enable {
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
