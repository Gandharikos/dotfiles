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
  inherit (lib.meta) getExe getExe';
  inherit (lib.modules) mkIf;
  inherit (config.my.gui) desktop;
  inherit (osConfig.dot.keyboard) keys;

  enable = osConfig.dot.gui.desktop.wayland.enable && desktop.shell.default == "noctalia";
  noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  noctaliaExe = getExe noctaliaPkg;
  noctaliaArgs =
    args:
    [
      noctaliaExe
      "msg"
    ]
    ++ args;
  screenRecorderArgs = action: [
    noctaliaExe
    "msg"
    "plugin"
    "noctalia/screen_recorder:service"
    "focused"
    action
  ];

  inherit (desktop) modKey;
in
{
  config = mkIf enable {
    programs.niri.settings = {
      binds =
        let
          spawn = args: { action.spawn = noctaliaArgs args; };
          xf86Binds = {
            "XF86AudioPlay" = {
              allow-when-locked = true;
              action.spawn = noctaliaArgs [
                "media"
                "toggle"
              ];
            };
            "XF86AudioPause" = {
              allow-when-locked = true;
              action.spawn = noctaliaArgs [
                "media"
                "toggle"
              ];
            };
            "XF86AudioNext" = {
              allow-when-locked = true;
              action.spawn = noctaliaArgs [
                "media"
                "next"
              ];
            };
            "XF86AudioPrev" = {
              allow-when-locked = true;
              action.spawn = noctaliaArgs [
                "media"
                "previous"
              ];
            };
            "XF86AudioMute" = {
              allow-when-locked = true;
              action.spawn = noctaliaArgs [
                "volume-mute"
              ];
            };
            "XF86AudioMicMute" = {
              allow-when-locked = true;
              action.spawn = noctaliaArgs [
                "mic-mute"
              ];
            };
            "XF86AudioRaiseVolume" = {
              allow-when-locked = true;
              repeat = true;
              action.spawn = noctaliaArgs [
                "volume-up"
              ];
            };
            "XF86AudioLowerVolume" = {
              allow-when-locked = true;
              repeat = true;
              action.spawn = noctaliaArgs [
                "volume-down"
              ];
            };
            "XF86MonBrightnessUp" = {
              allow-when-locked = true;
              repeat = true;
              action.spawn = noctaliaArgs [
                "brightness-up"
              ];
            };
            "XF86MonBrightnessDown" = {
              allow-when-locked = true;
              repeat = true;
              action.spawn = noctaliaArgs [
                "brightness-down"
              ];
            };
            "XF86KbdLightOnOff" = {
              allow-when-locked = true;
              action.spawn = [
                (getExe' pkgs.bash "bash")
                "-c"
                ''
                  current=$(${getExe' pkgs.brightnessctl "brightnessctl"} --device="*::kbd_backlight" get)
                  if [ "$current" -eq 0 ]; then
                    ${getExe' pkgs.brightnessctl "brightnessctl"} --device="*::kbd_backlight" set 100%
                  else
                    ${getExe' pkgs.brightnessctl "brightnessctl"} --device="*::kbd_backlight" set 0
                  fi
                ''
              ];
            };
            "XF86KbdBrightnessUp" = {
              allow-when-locked = true;
              repeat = true;
              action.spawn = [
                (getExe' pkgs.brightnessctl "brightnessctl")
                "--device=*::kbd_backlight"
                "set"
                "+10%"
              ];
            };
            "XF86KbdBrightnessDown" = {
              allow-when-locked = true;
              repeat = true;
              action.spawn = [
                (getExe' pkgs.brightnessctl "brightnessctl")
                "--device=*::kbd_backlight"
                "set"
                "10%-"
              ];
            };
          };
        in
        with keys;
        optionalAttrs (desktop.launcher.default == "shell") {
          "${modKey}+Space" = spawn [
            "panel-toggle"
            "launcher"
          ];
        }
        // {
          "${modKey}+V" = spawn [
            "panel-toggle"
            "clipboard"
          ];
          "${modKey}+W" = spawn [
            "panel-toggle"
            "launcher"
          ];
          "${modKey}+Escape" = spawn [
            "panel-toggle"
            "control-center"
            "system"
          ];
          "${modKey}+X" = spawn [
            "panel-toggle"
            "session"
          ];
          "${modKey}+Ctrl+C" = spawn [
            "panel-toggle"
            "control-center"
          ];
          "${modKey}+Shift+D" = spawn [
            "notification-dnd-toggle"
          ];
          "${modKey}+Shift+T" = spawn [
            "theme-mode-toggle"
          ];
          "${modKey}+Shift+${N}" = spawn [
            "nightlight-toggle"
          ];
          "${modKey}+${I}" = spawn [
            "caffeine-toggle"
          ];
          "Alt+Comma" = spawn [
            "settings-toggle"
          ];
          "${modKey}+Apostrophe" = spawn [
            "panel-toggle"
            "control-center"
            "notifications"
          ];
        }
        // {
          "${modKey}+Alt+L".action.spawn = noctaliaArgs [
            "session"
            "lock"
          ];
          "F10".action.spawn = screenRecorderArgs "toggle";
        }
        // xf86Binds;
    };
  };
}
