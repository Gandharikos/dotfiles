{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib.meta) getExe getExe';
  inherit (lib.my) runOnce uwsmApp uwsmScript withUWSM';
  inherit (lib.modules) mkIf;
  inherit (lib.strings) escapeShellArgs;

  inherit (config.my.gui) desktop;

  app = exe: args:
    if desktop.uwsm.enable
    then uwsmApp pkgs exe args
    else escapeShellArgs ([exe] ++ args);

  suspendScript =
    if desktop.uwsm.enable
    then
      uwsmScript pkgs "suspend-script" ''
        # check if any player has statutes "Playing"
        ${getExe pkgs.playerctl} -a status | ${
          getExe pkgs.ripgrep
        } Playing -q
        # only suspend if nothing is playing
        if [ $? == 1 ]; then
          ${getExe' pkgs.systemd "systemctl"} suspend
        fi
      ''
    else
      (pkgs.writeShellScript "suspend-script" ''
        # check if any player has statutes "Playing"
        ${getExe pkgs.playerctl} -a status | ${
          getExe pkgs.ripgrep
        } Playing -q
        # only suspend if nothing is playing
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
      uwsmScript pkgs "hypridle-dim-screen" ''
        ${getExe pkgs.brillo} -O
        ${getExe pkgs.brillo} -u 1000000 -S 10
      ''
    else "${getExe pkgs.brillo} -O; ${getExe pkgs.brillo} -u 1000000 -S 10";
  restoreScreen = app (getExe pkgs.brillo) ["-I" "-u" "500000"];

  # timeout after which DPMS kicks in
  timeout = 300;

  enable = desktop.idle == "hypridle" && desktop.wayland.enable;
  dmsPkg = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
  dms =
    if desktop.uwsm.enable
    then withUWSM' pkgs dmsPkg "dms"
    else getExe' dmsPkg "dms";
  dms_lock = "${dms} ipc call lock lock";
  lock_cmd =
    if desktop.lock == "hyprlock"
    then
      if desktop.uwsm.enable
      then runOnce pkgs "hyprlock" # avoid starting multiple hyprlock instances
      else getExe pkgs.hyprlock
    else if desktop.lock == "dms"
    then dms_lock
    else null;
  # to avoid having to press a key twice to turn on the display
  screen_on_cmd =
    if desktop.default == "hyprland"
    then app hyprctl' ["dispatch" "dpms" "on"]
    else if desktop.default == "niri"
    then app niri' ["msg" "action" "power-on-monitors"]
    else null;
  screen_off_cmd =
    if desktop.default == "hyprland"
    then app hyprctl' ["dispatch" "dpms" "off"]
    else if desktop.default == "niri"
    then app niri' ["msg" "action" "power-off-monitors"]
    else null;
in {
  config = mkIf enable {
    services.hypridle = {
      enable = true;

      settings = {
        general = {
          inherit lock_cmd;

          # lock before suspend
          before_sleep_cmd = app loginctl' ["lock-session"];

          after_sleep_cmd = screen_on_cmd;
        };

        listener = [
          {
            timeout = timeout - 10;
            # save the current brightness and dim the screen over a period of
            # 1 second
            on-timeout = dimScreen;
            # brighten the screen over a period of 500ms to the saved value
            on-resume = restoreScreen;
          }

          # turn off keyboard backlight, comment out this section if you dont have a keyboard backlight.
          {
            timeout = timeout / 2;
            # turn off keyboard backlight.
            on-timeout = app brightnessctl' ["-sd" "dell::kbd_backlight" "set" "0"];
            # turn on keyboard backlight.
            on-resume = app brightnessctl' ["-rd" "dell::kbd_backlight"];
          }
          {
            # 5min
            inherit timeout;
            # lock screen when timeout has passed
            on-timeout = app loginctl' ["lock-session"];
          }
          {
            inherit timeout;
            # screen off when timeout has passed
            on-timeout = screen_off_cmd;
            # screen on when activity is detected after timeout has fired.
            on-resume = screen_on_cmd;
          }
          {
            timeout = timeout + 10;
            # suspend pc
            on-timeout = suspendScript;
          }
        ];
      };
    };
  };
}
