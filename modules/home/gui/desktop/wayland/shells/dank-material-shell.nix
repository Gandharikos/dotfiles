{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf mkForce;
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.meta) getExe' getExe;
  inherit (config.my.gui) desktop;
  inherit (config.my.theme)
    avatar
    wallpaper
    ;
  inherit (config.my.keyboard) keys;

  enable = desktop.wayland.enable && desktop.shell.default == "dank-material-shell";
  dmsSettingsFile = lib.my.relativeToConfig "dank-material-shell/settings.json";
  settings = builtins.fromJSON (builtins.readFile dmsSettingsFile);

  dmsSessionFile = lib.my.relativeToConfig "dank-material-shell/session.json";
  sessionSettings = builtins.fromJSON (builtins.readFile dmsSessionFile);

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
  imports = [
    inputs.dms.homeModules.dank-material-shell
  ];
  config = mkIf enable {
    programs.dank-material-shell = {
      enable = true;
      systemd = {
        enable = true;
        restartIfChanged = true;
      };

      enableSystemMonitoring = true; # System monitoring widgets (dgop)
      enableDynamicTheming = true; # Wallpaper-based theming (matugen)
      enableVPN = true; # VPN management widget
      enableAudioWavelength = true; # Audio visualizer (cava)
      enableCalendarEvents = false; # Calendar integration (khal)
      session =
        sessionSettings
        // optionalAttrs (wallpaper != null) {
          wallpaperPath = toString wallpaper;
          wallpaperPathLight = toString wallpaper;
          wallpaperPathDark = toString wallpaper;
        };
      inherit settings;

      plugins =
        let
          dmsPluginsRepo = pkgs.fetchFromGitHub {
            owner = "AvengeMedia";
            repo = "dms-plugins";
            rev = "829922a8f11949b1c13ae8bd14d7176f9165b6f5";
            hash = "sha256-KYx+n1stxLT4R9IDVRx3/Cl7TjCcBZjnQchbrXaBT2o=";
          };
        in
        {
          dankPomodoroTimer = {
            enable = true;
            src = "${dmsPluginsRepo}/DankPomodoroTimer";
          };
          catWidget = {
            enable = true;
            src = pkgs.fetchFromGitHub {
              owner = "xi-ve";
              repo = "cat-dms";
              rev = "eb7b5138b672be3c06445dd80de6bc30c3076030";
              hash = "sha256-KD2G805Hq0K9aPW9Aq4hNo2XKji4kzdc24M4AcRhsPk=";
            };
          };
          dmsScreenshot = {
            enable = true;
            src = pkgs.fetchFromGitHub {
              owner = "JDKamalakar";
              repo = "DMS-Screenshot";
              rev = "695a12428b0cc85db0e9cd6b469f776342950fa7";
              hash = "sha256-3KQCIrVclcqaQiwZhv7dwNbTjPL/+jzi8I3h0yn35w8=";
            };
          };
          emojiLauncher = {
            enable = true;
            src = pkgs.fetchFromGitHub {
              owner = "devnullvoid";
              repo = "dms-emoji-launcher";
              rev = "1c0a7d337a52b48f9499060076703a35e8dd4f4f";
              hash = "sha256-NQ14YenDiNK2VqXQ3z7jAkatbSRtYJHhOhvv7AJlUD8=";
            };
          };
          screen-recorder = {
            enable = true;
            src = pkgs.fetchFromGitHub {
              owner = "arqueon";
              repo = "dms-screen-recorder";
              rev = "7206b590d69a165d30b5bbb66b033f1a15b49aff";
              hash = "sha256-ndH8KHH+gzFIXWceqeUmy/w7oGj7ZvCEIacBfV1D+KU=";
            };
          };
        };
    };
    home.file = optionalAttrs (avatar != null) {
      ".face".source = avatar;
    };
    programs.lazyvim.extraPlugins = [
      pkgs.vimPlugins.base16-nvim
    ];
    wayland.windowManager.hyprland.settings = with keys; {
      bindd =
        let
          spotlight = dms' "spotlight toggle";
          clipboard = dms' "clipboard toggle";
          overview = dms' "hypr toggleOverview";
          monitor = dms' "processlist toggle";
          powermenu = dms' "powermenu toggle";
          control_center = dms' "control-center toggle";
          notepad = dms' "notepad toggle";
          notifications = dms' "notifications toggle";
          dnd = dms' "notifications toggleDoNotDisturb";
          settings = dms' "settings toggle";
          theme_toggle = dms' "theme toggle";
          night_toggle = dms' "night toggle";
          inhibit = dms' "inhibit toggle";
          lock = dms' "lock toggle";
          recorder_toggle = dms' "screen-recorder toggle";
          recorder_save = dms' "screen-recorder saveReplay";
        in
        [
          "$mod, space, Toggle App Launcher, exec, ${spotlight}"
          "$mod, V, Toggle Clipboard History, exec, ${clipboard}"
          "$mod, Tab, Toggle Overview, exec, ${overview}"
          "$mod, Escape, Toggle System Monitor, exec, ${monitor}"
          "$mod, X, Toggle Power Menu, exec, ${powermenu}"
          "$mod, C, Toggle Control Center, exec, ${control_center}"
          "$mod, ${N}, Toggle Notepad, exec, ${notepad}"
          "$mod SHIFT, D, Toggle Do Not Disturb, exec, ${dnd}"
          "$mod SHIFT, T, Toggle Theme Mode, exec, ${theme_toggle}"
          "$mod SHIFT, ${N}, Toggle Night Mode, exec, ${night_toggle}"
          "$mod, ${I}, Toggle Inhibit, exec, ${inhibit}"
          "ALT, Comma, Toggle Settings, exec, ${settings}"
          "$mod, Apostrophe, Toggle Notifications, exec, ${notifications}"
        ]
        ++ [
          "SUPER ALT, L, Toggle Lock, exec, ${lock}"
          ", F10, Toggle Screen Recording, exec, ${recorder_toggle}"
          "SHIFT, F10, Save Replay Buffer, exec, ${recorder_save}"
        ];
      binddl = mkForce (
        let
          mpris_playpause = dms' "mpris playPause";
          mpris_next = dms' "mpris next";
          mpris_prev = dms' "mpris previous";
          audio_mute = dms' "audio mute";
          audio_micmute = dms' "audio micmute";
        in
        [
          ", XF86AudioPlay, Play/Pause, exec, ${mpris_playpause}"
          ", XF86AudioPause, Play/Pause, exec, ${mpris_playpause}"
          ", XF86AudioNext, Skip to Next Track, exec, ${mpris_next}"
          ", XF86AudioPrev, Return to Previous Track, exec, ${mpris_prev}"
          ", XF86AudioMute, Mute/Unmute Volume, exec, ${audio_mute}"
          ", XF86AudioMicMute, Mute/Unmute Microphone, exec, ${audio_micmute}"
        ]
      );
      binddel = mkForce (
        let
          increment_volume = dms' "audio increment 2";
          decrement_volume = dms' "audio decrement 2";
          brightness_up = dms' "brightness increment 5 \"\"";
          brightness_down = dms' "brightness decrement 5 \"\"";
        in
        [
          ", XF86AudioRaiseVolume, Increase Volume, exec, ${increment_volume}"
          ", XF86AudioLowerVolume, Decrease Volume, exec, ${decrement_volume}"
          ", XF86MonBrightnessUp, Increase Brightness, exec, ${brightness_up}"
          ", XF86MonBrightnessDown, Decrease Brightness, exec, ${brightness_down}"
        ]
      );
    };
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
        {
          "${modKey}+Space" = spawn [
            "spotlight"
            "toggle"
          ];
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
            "screen-recorder"
            "toggle"
          ];
          "Shift+F10".action.spawn = dms' [
            "screen-recorder"
            "saveReplay"
          ];
        }
        // xf86Binds;
    };
  };
}
