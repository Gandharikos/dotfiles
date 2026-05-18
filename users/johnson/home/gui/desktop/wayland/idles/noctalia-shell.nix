{
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) escapeShellArgs;
  inherit (config.my.gui) desktop;

  idleCfg = desktop.idle;
  enable =
    osConfig.dot.gui.desktop.wayland.enable
    && idleCfg.default == "noctalia-shell"
    && (config.programs.noctalia-shell.enable or false);
  brightnessctl = getExe pkgs.brightnessctl;
  screenOffTimeout = lib.max 0 (idleCfg.timeout - 10);
  keyboardBacklightTimeout = idleCfg.timeout / 2;
  keyboardBacklightOff = escapeShellArgs [
    brightnessctl
    "-sd"
    idleCfg.keyboardBacklight.device
    "set"
    "0"
  ];
  keyboardBacklightOn = escapeShellArgs [
    brightnessctl
    "-rd"
    idleCfg.keyboardBacklight.device
  ];
  keyboardBacklightCommands =
    if idleCfg.keyboardBacklight.enable then
      builtins.toJSON [
        {
          timeout = keyboardBacklightTimeout;
          command = keyboardBacklightOff;
          resumeCommand = keyboardBacklightOn;
        }
      ]
    else
      "[]";
in
{
  config = mkIf enable {
    programs.noctalia-shell.settings.idle = {
      enabled = true;
      inherit screenOffTimeout;
      lockTimeout = idleCfg.timeout;
      suspendTimeout = idleCfg.timeout + 10;
      customCommands = keyboardBacklightCommands;
    };
  };
}
