{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.meta) getExe';
  inherit (lib.modules) mkIf mkForce;
  inherit (lib.strings) escapeShellArgs;
  inherit (config.my.gui) desktop;
  inherit (config.my.keyboard) keys;
  inherit (config.my.theme)
    avatar
    wallpaper
    ;

  enable = desktop.wayland.enable && desktop.shell.default == "noctalia-shell";
  noctaliaSettingsFile = lib.my.relativeToConfig "noctalia/settings.json";
  settings = builtins.fromJSON (builtins.readFile noctaliaSettingsFile);

  noctaliaPluginsFile = lib.my.relativeToConfig "noctalia/plugins.json";
  plugins = builtins.fromJSON (builtins.readFile noctaliaPluginsFile);

  noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  uwsm = getExe' pkgs.uwsm "uwsm";
  noctaliaExe = getExe' noctaliaPkg "noctalia-shell";
  noctaliaCmd = [
    uwsm
    "app"
    "--"
    noctaliaExe
  ];
  noctaliaArgs =
    args:
    noctaliaCmd
    ++ [
      "ipc"
      "call"
    ]
    ++ args;
  noctalia = args: escapeShellArgs (noctaliaArgs args);
  noctaliaRecorder =
    action:
    escapeShellArgs (noctaliaArgs [
      "plugin:screen-recorder"
      action
    ]);

  inherit (desktop) modKey;
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  config = mkIf enable {
    programs.noctalia-shell = {
      enable = true;

      systemd = {
        enable = true;
      };

      settings = settings // {
        general =
          settings.general
          // optionalAttrs (avatar != null) { avatarImage = toString avatar; }
          // {
            keybinds = settings.general.keybinds // {
              keyLeft = settings.general.keybinds.keyLeft ++ [ "Ctrl+${keys.H}" ];
              keyDown = settings.general.keybinds.keyDown ++ [ "Ctrl+${keys.J}" ];
              keyUp = settings.general.keybinds.keyUp ++ [ "Ctrl+${keys.K}" ];
              keyRight = settings.general.keybinds.keyRight ++ [ "Ctrl+${keys.L}" ];
            };
          };
        wallpaper =
          settings.wallpaper
          // optionalAttrs (wallpaper != null) {
            enabled = true;
            directory = builtins.dirOf (toString wallpaper);
          };
      };

      inherit plugins;
    };

    wayland.windowManager.hyprland.settings = with keys; {
      bindd =
        let
          launcher = noctalia [
            "launcher"
            "toggle"
          ];
          clipboard = noctalia [
            "launcher"
            "clipboard"
          ];
          windows = noctalia [
            "launcher"
            "windows"
          ];
          monitor = noctalia [
            "systemMonitor"
            "toggle"
          ];
          sessionMenu = noctalia [
            "sessionMenu"
            "toggle"
          ];
          controlCenter = noctalia [
            "controlCenter"
            "toggle"
          ];
          settings = noctalia [
            "settings"
            "toggle"
          ];
          notifications = noctalia [
            "notifications"
            "toggleHistory"
          ];
          dnd = noctalia [
            "notifications"
            "toggleDND"
          ];
          darkMode = noctalia [
            "darkMode"
            "toggle"
          ];
          nightLight = noctalia [
            "nightLight"
            "toggle"
          ];
          inhibit = noctalia [
            "idleInhibitor"
            "toggle"
          ];
          lock = noctalia [
            "lockScreen"
            "lock"
          ];
        in
        [
          "$mod, space, Toggle App Launcher, exec, ${launcher}"
          "$mod, V, Toggle Clipboard History, exec, ${clipboard}"
          "$mod, Tab, Toggle Window Launcher, exec, ${windows}"
          "$mod, Escape, Toggle System Monitor, exec, ${monitor}"
          "$mod, X, Toggle Session Menu, exec, ${sessionMenu}"
          "$mod, C, Toggle Control Center, exec, ${controlCenter}"
          "$mod SHIFT, D, Toggle Do Not Disturb, exec, ${dnd}"
          "$mod SHIFT, T, Toggle Theme Mode, exec, ${darkMode}"
          "$mod SHIFT, ${N}, Toggle Night Light, exec, ${nightLight}"
          "$mod, ${I}, Toggle Inhibit, exec, ${inhibit}"
          "ALT, Comma, Toggle Settings, exec, ${settings}"
          "$mod, Apostrophe, Toggle Notifications, exec, ${notifications}"
          "SUPER ALT, L, Lock Screen, exec, ${lock}"
          ", F10, Toggle Screen Recording, exec, ${noctaliaRecorder "toggle"}"
        ];

      binddl = mkForce (
        let
          playPause = noctalia [
            "media"
            "playPause"
          ];
          next = noctalia [
            "media"
            "next"
          ];
          previous = noctalia [
            "media"
            "previous"
          ];
          muteOutput = noctalia [
            "volume"
            "muteOutput"
          ];
          muteInput = noctalia [
            "volume"
            "muteInput"
          ];
          brightnessctl = getExe' pkgs.brightnessctl "brightnessctl";
          kbdToggle = pkgs.writeShellScript "kbd-toggle" ''
            current=$(${brightnessctl} --device="*::kbd_backlight" get)
            if [ "$current" -eq 0 ]; then
              ${brightnessctl} --device="*::kbd_backlight" set 100%
            else
              ${brightnessctl} --device="*::kbd_backlight" set 0
            fi
          '';
        in
        [
          ", XF86AudioPlay, Play/Pause, exec, ${playPause}"
          ", XF86AudioPause, Play/Pause, exec, ${playPause}"
          ", XF86AudioNext, Skip to Next Track, exec, ${next}"
          ", XF86AudioPrev, Return to Previous Track, exec, ${previous}"
          ", XF86AudioMute, Mute/Unmute Volume, exec, ${muteOutput}"
          ", XF86AudioMicMute, Mute/Unmute Microphone, exec, ${muteInput}"
          ", XF86KbdLightOnOff, Toggle Keyboard Backlight, exec, ${kbdToggle}"
        ]
      );

      binddel = mkForce (
        let
          increaseVolume = noctalia [
            "volume"
            "increase"
          ];
          decreaseVolume = noctalia [
            "volume"
            "decrease"
          ];
          increaseBrightness = noctalia [
            "brightness"
            "increase"
          ];
          decreaseBrightness = noctalia [
            "brightness"
            "decrease"
          ];
          brightnessctl = getExe' pkgs.brightnessctl "brightnessctl";
          increaseKbdBrightness = "${brightnessctl} --device=*::kbd_backlight set +10%";
          decreaseKbdBrightness = "${brightnessctl} --device=*::kbd_backlight set 10%-";
        in
        [
          ", XF86AudioRaiseVolume, Increase Volume, exec, ${increaseVolume}"
          ", XF86AudioLowerVolume, Decrease Volume, exec, ${decreaseVolume}"
          ", XF86MonBrightnessUp, Increase Brightness, exec, ${increaseBrightness}"
          ", XF86MonBrightnessDown, Decrease Brightness, exec, ${decreaseBrightness}"
          ", XF86KbdBrightnessUp, Increase Keyboard Brightness, exec, ${increaseKbdBrightness}"
          ", XF86KbdBrightnessDown, Decrease Keyboard Brightness, exec, ${decreaseKbdBrightness}"
        ]
      );
    };

    programs.niri.settings = {
      binds =
        let
          spawn = args: { action.spawn = noctaliaArgs args; };
          xf86Binds = {
            "XF86AudioPlay" = {
              allow-when-locked = true;
              action.spawn = noctaliaArgs [
                "media"
                "playPause"
              ];
            };
            "XF86AudioPause" = {
              allow-when-locked = true;
              action.spawn = noctaliaArgs [
                "media"
                "playPause"
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
                "volume"
                "muteOutput"
              ];
            };
            "XF86AudioMicMute" = {
              allow-when-locked = true;
              action.spawn = noctaliaArgs [
                "volume"
                "muteInput"
              ];
            };
            "XF86AudioRaiseVolume" = {
              allow-when-locked = true;
              repeat = true;
              action.spawn = noctaliaArgs [
                "volume"
                "increase"
              ];
            };
            "XF86AudioLowerVolume" = {
              allow-when-locked = true;
              repeat = true;
              action.spawn = noctaliaArgs [
                "volume"
                "decrease"
              ];
            };
            "XF86MonBrightnessUp" = {
              allow-when-locked = true;
              repeat = true;
              action.spawn = noctaliaArgs [
                "brightness"
                "increase"
              ];
            };
            "XF86MonBrightnessDown" = {
              allow-when-locked = true;
              repeat = true;
              action.spawn = noctaliaArgs [
                "brightness"
                "decrease"
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
        {
          "${modKey}+Space" = spawn [
            "launcher"
            "toggle"
          ];
          "${modKey}+V" = spawn [
            "launcher"
            "clipboard"
          ];
          "${modKey}+W" = spawn [
            "launcher"
            "windows"
          ];
          "${modKey}+Escape" = spawn [
            "systemMonitor"
            "toggle"
          ];
          "${modKey}+X" = spawn [
            "sessionMenu"
            "toggle"
          ];
          "${modKey}+Ctrl+C" = spawn [
            "controlCenter"
            "toggle"
          ];
          "${modKey}+Shift+D" = spawn [
            "notifications"
            "toggleDND"
          ];
          "${modKey}+Shift+T" = spawn [
            "darkMode"
            "toggle"
          ];
          "${modKey}+Shift+${N}" = spawn [
            "nightLight"
            "toggle"
          ];
          "${modKey}+${I}" = spawn [
            "idleInhibitor"
            "toggle"
          ];
          "Alt+Comma" = spawn [
            "settings"
            "toggle"
          ];
          "${modKey}+Apostrophe" = spawn [
            "notifications"
            "toggleHistory"
          ];
        }
        // {
          "${modKey}+Alt+L".action.spawn = noctaliaArgs [
            "lockScreen"
            "lock"
          ];
          "F10".action.spawn = noctaliaArgs [
            "plugin:screen-recorder"
            "toggle"
          ];
        }
        // xf86Binds;
    };

    home.file.".cache/noctalia/wallpapers.json" = mkIf (wallpaper != null) {
      text = builtins.toJSON {
        defaultWallpaper = toString wallpaper;
        wallpapers = { };
      };
    };
  };
}
