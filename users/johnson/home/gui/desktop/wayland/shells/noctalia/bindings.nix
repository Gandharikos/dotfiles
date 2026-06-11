{
  inputs,
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.meta) getExe getExe';
  inherit (lib.modules) mkIf mkForce;
  inherit (lib.strings) escapeShellArgs;
  inherit (config.my.gui) desktop;
  inherit (osConfig.dot.keyboard) keys;
  inherit (config.nixporn) wallpaper;

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
  noctalia = args: escapeShellArgs (noctaliaArgs args);
  noctaliaRecorder =
    action:
    escapeShellArgs (noctaliaArgs [
      "plugin"
      "noctalia/screen_recorder:service"
      "all"
      action
    ]);
  noctaliaWallpapersSeed =
    if wallpaper == null then
      null
    else
      pkgs.writeText "noctalia-wallpapers.json" (
        builtins.toJSON {
          defaultWallpaper = toString wallpaper;
          wallpapers = { };
          usedRandomWallpapers = { };
        }
      );

  inherit (desktop) modKey;
in
{
  config = mkIf enable {
    wayland.windowManager.hyprland.settings = with keys; {
      bindd =
        let
          launcher = noctalia [
            "panel-toggle"
            "launcher"
          ];
          clipboard = noctalia [
            "panel-toggle"
            "clipboard"
          ];
          windows = noctalia [
            "panel-toggle"
            "launcher"
          ];
          monitor = noctalia [
            "panel-toggle"
            "control-center"
            "system"
          ];
          sessionMenu = noctalia [
            "panel-toggle"
            "session"
          ];
          controlCenter = noctalia [
            "panel-toggle"
            "control-center"
          ];
          settings = noctalia [
            "settings-toggle"
          ];
          notifications = noctalia [
            "panel-toggle"
            "control-center"
            "notifications"
          ];
          dnd = noctalia [
            "notification-dnd-toggle"
          ];
          darkMode = noctalia [
            "theme-mode-toggle"
          ];
          nightLight = noctalia [
            "nightlight-toggle"
          ];
          inhibit = noctalia [
            "caffeine-toggle"
          ];
          lock = noctalia [
            "session"
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
            "toggle"
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
            "volume-mute"
          ];
          muteInput = noctalia [
            "mic-mute"
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
            "volume-up"
          ];
          decreaseVolume = noctalia [
            "volume-down"
          ];
          increaseBrightness = noctalia [
            "brightness-up"
          ];
          decreaseBrightness = noctalia [
            "brightness-down"
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
        {
          "${modKey}+Space" = spawn [
            "panel-toggle"
            "launcher"
          ];
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
          "F10".action.spawn = noctaliaArgs [
            "plugin"
            "noctalia/screen_recorder:service"
            "all"
            "toggle"
          ];
        }
        // xf86Binds;
    };

    home.activation.seedNoctaliaWallpapers = mkIf (wallpaper != null) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cache_file="${config.xdg.cacheHome}/noctalia/wallpapers.json"

        if [ -L "$cache_file" ]; then
          rm -f "$cache_file"
        fi

        if [ ! -e "$cache_file" ]; then
          mkdir -p "$(dirname "$cache_file")"
          cp ${noctaliaWallpapersSeed} "$cache_file"
          chmod 0644 "$cache_file"
        fi
      ''
    );
  };
}
