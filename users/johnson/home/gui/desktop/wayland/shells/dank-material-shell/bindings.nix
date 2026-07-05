{
  inputs,
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe' getExe;
  inherit (config.my.gui) desktop;
  inherit (osConfig.dot.keyboard) keys;
  enable = osConfig.dot.gui.desktop.wayland.enable && desktop.shell.default == "dank-material-shell";
  dmsPkg = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
  uwsm = getExe' pkgs.uwsm "uwsm";
  dmsExe = getExe' dmsPkg "dms";
  dmsCmd = [
    uwsm
    "app"
    "--"
    dmsExe
  ];
  dmsCmdStr = builtins.concatStringsSep " " dmsCmd;
  dms' =
    args:
    if builtins.isList args then
      dmsCmd
      ++ [
        "ipc"
        "call"
      ]
      ++ args
    else
      "${dmsCmdStr} ipc call ${args}";

  inherit (desktop) modKey;
in
{
  config = mkIf enable {
    programs.niri.settings = {
      binds =
        let
          spawn = args: { action.spawn = dms' args; };
          xf86Binds = {
            "XF86AudioPlay" = {
              allow-when-locked = true;
              action.spawn = dms' [
                "mpris"
                "playPause"
              ];
            };
            "XF86AudioPause" = {
              allow-when-locked = true;
              action.spawn = dms' [
                "mpris"
                "playPause"
              ];
            };
            "XF86AudioNext" = {
              allow-when-locked = true;
              action.spawn = dms' [
                "mpris"
                "next"
              ];
            };
            "XF86AudioPrev" = {
              allow-when-locked = true;
              action.spawn = dms' [
                "mpris"
                "previous"
              ];
            };
            "XF86AudioMute" = {
              allow-when-locked = true;
              action.spawn = dms' [
                "audio"
                "mute"
              ];
            };
            "XF86AudioMicMute" = {
              allow-when-locked = true;
              action.spawn = dms' [
                "audio"
                "micmute"
              ];
            };
            "XF86AudioRaiseVolume" = {
              allow-when-locked = true;
              repeat = true;
              action.spawn = dms' [
                "audio"
                "increment"
                "2"
              ];
            };
            "XF86AudioLowerVolume" = {
              allow-when-locked = true;
              repeat = true;
              action.spawn = dms' [
                "audio"
                "decrement"
                "2"
              ];
            };
            "XF86MonBrightnessUp" = {
              allow-when-locked = true;
              repeat = true;
              action.spawn = dms' [
                "brightness"
                "increment"
                "5"
                ""
              ];
            };
            "XF86MonBrightnessDown" = {
              allow-when-locked = true;
              repeat = true;
              action.spawn = dms' [
                "brightness"
                "decrement"
                "5"
                ""
              ];
            };
            "XF86KbdLightOnOff" = {
              allow-when-locked = true;
              action.spawn = [
                "${getExe pkgs.bash}"
                "-c"
                ''
                  device=$(${dmsCmdStr} ipc call brightness list | ${getExe pkgs.ripgrep} -o '^[^:]+:[^:]+::kbd_backlight' | ${getExe' pkgs.coreutils "head"} -1)
                  if [ -n "$device" ]; then
                    current=$(${getExe pkgs.brightnessctl} --device="''${device#*:}" get)
                    if [ "$current" -eq 0 ]; then
                      ${dmsCmdStr} ipc call brightness set 100 "$device"
                    else
                      ${dmsCmdStr} ipc call brightness set 0 "$device"
                    fi
                  fi
                ''
              ];
            };
            "XF86KbdBrightnessUp" = {
              allow-when-locked = true;
              repeat = true;
              action.spawn = [
                "${getExe pkgs.bash}"
                "-c"
                ''
                  device=$(${dmsCmdStr} ipc call brightness list | ${getExe pkgs.ripgrep} -o '^[^:]+:[^:]+::kbd_backlight' | ${getExe' pkgs.coreutils "head"} -1)
                  [ -n "$device" ] && ${dmsCmdStr} ipc call brightness increment 10 "$device"
                ''
              ];
            };
            "XF86KbdBrightnessDown" = {
              allow-when-locked = true;
              repeat = true;
              action.spawn = [
                "${getExe pkgs.bash}"
                "-c"
                ''
                  device=$(${dmsCmdStr} ipc call brightness list | ${getExe pkgs.ripgrep} -o '^[^:]+:[^:]+::kbd_backlight' | ${getExe' pkgs.coreutils "head"} -1)
                  [ -n "$device" ] && ${dmsCmdStr} ipc call brightness decrement 10 "$device"
                ''
              ];
            };
          };
        in
        with keys;
        optionalAttrs (desktop.launcher.default == "shell") {
          "${modKey}+Space" = spawn [
            "spotlight"
            "toggle"
          ];
        }
        // {
          "${modKey}+V" = spawn [
            "clipboard"
            "toggle"
          ];
          "${modKey}+Escape" = spawn [
            "processlist"
            "toggle"
          ];
          "${modKey}+X" = spawn [
            "powermenu"
            "toggle"
          ];
          "${modKey}+Ctrl+C" = spawn [
            "control-center"
            "toggle"
          ];
          "${modKey}+${N}" = spawn [
            "notepad"
            "toggle"
          ];
          "${modKey}+Shift+D" = spawn [
            "notifications"
            "toggleDoNotDisturb"
          ];
          "${modKey}+Shift+T" = spawn [
            "theme"
            "toggle"
          ];
          "${modKey}+Shift+${N}" = spawn [
            "night"
            "toggle"
          ];
          "${modKey}+${I}" = spawn [
            "inhibit"
            "toggle"
          ];
          "Alt+Comma" = spawn [
            "settings"
            "toggle"
          ];
          "${modKey}+Apostrophe" = spawn [
            "notifications"
            "toggle"
          ];
        }
        // {
          "${modKey}+Alt+L".action.spawn = dms' [
            "lock"
            "toggle"
          ];
          "F10".action.spawn = dms' [
            "screenRecorder"
            "toggleRecording"
          ];
        }
        // xf86Binds;
    };
  };
}
