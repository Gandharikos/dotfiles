{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) optionals;
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

  qsPkg = inputs.noctalia-qs.packages.${pkgs.stdenv.hostPlatform.system}.default;
  uwsm = getExe' pkgs.uwsm "uwsm";
  qsExe = getExe' qsPkg "qs";
  qsCmd = [
    uwsm
    "app"
    "--"
    qsExe
  ];
  noctaliaArgs =
    args:
    qsCmd
    ++ [
      "-c"
      "noctalia-shell"
      "ipc"
      "call"
    ]
    ++ args;
  noctalia = args: escapeShellArgs (noctaliaArgs args);

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
        general = settings.general // optionalAttrs (avatar != null) { avatarImage = toString avatar; };
        colorSchemes = settings.colorSchemes // {
          useWallpaperColors = wallpaper != null;
        };
        wallpaper =
          settings.wallpaper
          // optionalAttrs (wallpaper != null) {
            enabled = true;
            directory = builtins.dirOf (toString wallpaper);
          };
      };
    };

    wayland.windowManager.hyprland.settings = with keys; {
      exec-once = optionals (wallpaper != null) [
        (noctalia [
          "wallpaper"
          "set"
          (toString wallpaper)
        ])
      ];

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
        in
        [
          ", XF86AudioPlay, Play/Pause, exec, ${playPause}"
          ", XF86AudioPause, Play/Pause, exec, ${playPause}"
          ", XF86AudioNext, Skip to Next Track, exec, ${next}"
          ", XF86AudioPrev, Return to Previous Track, exec, ${previous}"
          ", XF86AudioMute, Mute/Unmute Volume, exec, ${muteOutput}"
          ", XF86AudioMicMute, Mute/Unmute Microphone, exec, ${muteInput}"
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
        in
        [
          ", XF86AudioRaiseVolume, Increase Volume, exec, ${increaseVolume}"
          ", XF86AudioLowerVolume, Decrease Volume, exec, ${decreaseVolume}"
          ", XF86MonBrightnessUp, Increase Brightness, exec, ${increaseBrightness}"
          ", XF86MonBrightnessDown, Decrease Brightness, exec, ${decreaseBrightness}"
        ]
      );
    };

    programs.niri.settings = {
      spawn-at-startup = optionals (wallpaper != null) [
        {
          command = noctaliaArgs [
            "wallpaper"
            "set"
            (toString wallpaper)
          ];
        }
      ];

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
