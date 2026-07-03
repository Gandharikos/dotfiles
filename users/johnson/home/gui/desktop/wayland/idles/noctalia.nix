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
    && idleCfg.default == "shell"
    && desktop.shell.default == "noctalia"
    && (config.programs.noctalia.enable or false);
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
in
{
  config = mkIf enable {
    programs.noctalia.settings.idle = {
      pre_action_fade_seconds = 5;
      behavior_order = lib.optional idleCfg.keyboardBacklight.enable "keyboard-backlight" ++ [
        "screen-off"
        "lock"
        "suspend"
      ];
      behavior = {
        "screen-off" = {
          enabled = true;
          timeout = screenOffTimeout;
          action = "screen_off";
          command = "noctalia:dpms-off";
          resume_command = "noctalia:dpms-on";
        };
        lock = {
          enabled = true;
          inherit (idleCfg) timeout;
          action = "lock";
          command = "noctalia:session lock";
        };
        suspend = {
          enabled = true;
          timeout = idleCfg.timeout + 10;
          action = "suspend";
        };
      }
      // lib.optionalAttrs idleCfg.keyboardBacklight.enable {
        "keyboard-backlight" = {
          enabled = true;
          timeout = keyboardBacklightTimeout;
          action = "command";
          command = keyboardBacklightOff;
          resume_command = keyboardBacklightOn;
        };
      };
    };
  };
}
