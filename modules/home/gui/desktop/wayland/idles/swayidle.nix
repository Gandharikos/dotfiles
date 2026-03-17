{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib.lists) optionals;
  inherit (lib.meta) getExe getExe';
  inherit (lib.my) runOnce uwsmApp uwsmScript withUWSM';
  inherit (lib.modules) mkIf;
  inherit (lib.strings) escapeShellArgs;

  inherit (config.my.gui) desktop;
  cfg = desktop.idle;

  app = exe: args:
    if desktop.uwsm.enable
    then uwsmApp pkgs exe args
    else escapeShellArgs ([exe] ++ args);

  suspendScript =
    if desktop.uwsm.enable
    then
      uwsmScript pkgs "swayidle-suspend-script" ''
        ${getExe pkgs.playerctl} -a status | ${
          getExe pkgs.ripgrep
        } Playing -q
        if [ $? == 1 ]; then
          ${getExe' pkgs.systemd "systemctl"} suspend
        fi
      ''
    else
      (pkgs.writeShellScript "swayidle-suspend-script" ''
        ${getExe pkgs.playerctl} -a status | ${
          getExe pkgs.ripgrep
        } Playing -q
        if [ $? == 1 ]; then
          ${getExe' pkgs.systemd "systemctl"} suspend
        fi
      '').outPath;

  loginctl' = getExe' pkgs.systemd "loginctl";
  brightnessctl' = getExe pkgs.brightnessctl;
  hyprctl' = getExe' pkgs.hyprland "hyprctl";
  niri' = getExe' pkgs.niri "niri";
  dimScreen =
    if desktop.uwsm.enable
    then
      uwsmScript pkgs "swayidle-dim-screen" ''
        ${getExe pkgs.brillo} -O
        ${getExe pkgs.brillo} -u 1000000 -S 10
      ''
    else
      (pkgs.writeShellScript "swayidle-dim-screen" ''
        ${getExe pkgs.brillo} -O
        ${getExe pkgs.brillo} -u 1000000 -S 10
      '').outPath;
  restoreScreen = app (getExe pkgs.brillo) ["-I" "-u" "500000"];

  inherit (cfg) timeout;

  enable = desktop.idle.default == "swayidle" && desktop.wayland.enable;
  dmsPkg = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
  dms =
    if desktop.uwsm.enable
    then withUWSM' pkgs dmsPkg "dms"
    else getExe' dmsPkg "dms";
  dmsLock = "${dms} ipc call lock lock";
  lockCmd =
    if desktop.lock.default == "hyprlock"
    then
      if desktop.uwsm.enable
      then runOnce pkgs "hyprlock"
      else getExe pkgs.hyprlock
    else if desktop.lock.default == "dms"
    then dmsLock
    else null;
  screenOnCmd =
    if desktop.default == "hyprland"
    then app hyprctl' ["dispatch" "dpms" "on"]
    else if desktop.default == "niri"
    then app niri' ["msg" "action" "power-on-monitors"]
    else null;
  screenOffCmd =
    if desktop.default == "hyprland"
    then app hyprctl' ["dispatch" "dpms" "off"]
    else if desktop.default == "niri"
    then app niri' ["msg" "action" "power-off-monitors"]
    else null;
in {
  config = mkIf enable {
    services.swayidle = {
      enable = true;

      events =
        {
          before-sleep = app loginctl' ["lock-session"];
        }
        // lib.optionalAttrs (lockCmd != null) {
          lock = lockCmd;
        }
        // lib.optionalAttrs (screenOnCmd != null) {
          after-resume = screenOnCmd;
        };

      timeouts =
        [
          {
            timeout = timeout - 10;
            command = dimScreen;
            resumeCommand = restoreScreen;
          }
          {
            inherit timeout;
            command = app loginctl' ["lock-session"];
          }
        ]
        ++ optionals cfg.keyboardBacklight.enable [
          {
            timeout = timeout / 2;
            command = app brightnessctl' ["-sd" cfg.keyboardBacklight.device "set" "0"];
            resumeCommand = app brightnessctl' ["-rd" cfg.keyboardBacklight.device];
          }
        ]
        ++ optionals (screenOffCmd != null) [
          {
            inherit timeout;
            command = screenOffCmd;
            resumeCommand = screenOnCmd;
          }
        ]
        ++ [
          {
            timeout = timeout + 10;
            command = suspendScript;
          }
        ];
    };
  };
}
