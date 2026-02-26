{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf mkForce;
  inherit (lib.lists) optionals;
  inherit (lib.my) isWayland withUWSM';

  enable = isWayland config;

  dms = withUWSM' pkgs inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default "dms";
  dms' = cmd: "${dms} ipc call ${cmd}";
in {
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
      enableCalendarEvents = true; # Calendar integration (khal)
    };
    wayland.windowManager.hyprland.settings = {
      bindd = let
        spotlight = dms' "spotlight toggle";
        clipboard = dms' "clipboard toggle";
        overview = dms' "hypr toggleOverview";
        monitor = dms' "processlist toggle";
        powermenu = dms' "powermenu toggle";
        notifications = dms' "notifications toggle";
        settings = dms' "settings toggle";
        lock = dms' "lock toggle";
      in
        [
          "$mod, space, Toggle App Launcher, exec, ${spotlight}"
          "$mod, V, Toggle Clipboard History, exec, ${clipboard}"
          "$mod, Tab, Toggle Overview, exec, ${overview}"
          "$mod, Escape, Toggle System Monitor, exec, ${monitor}"
          "$mod, X, Toggle Power Menu, exec, ${powermenu}"
          "ALT, Comma, Toggle Settings, exec, ${settings}"
          "$mod, Apostrophe, Toggle Notifications, exec, ${notifications}"
        ]
        ++ optionals (config.my.desktop.lock == "dms") [
          "SUPER ALT, L, Toggle Lock, exec, ${lock}"
        ];
      binddl = mkForce (let
        mpris_playpause = dms' "mpris playPause";
        mpris_next = dms' "mpris next";
        mpris_prev = dms' "mpris previous";
        audio_mute = dms' "audio mute";
        audio_micmute = dms' "audio micmute";
      in [
        ", XF86AudioPlay, Play/Pause, exec, ${mpris_playpause}"
        ", XF86AudioPause, Play/Pause, exec, ${mpris_playpause}"
        ", XF86AudioNext, Skip to Next Track, exec, ${mpris_next}"
        ", XF86AudioPrev, Return to Previous Track, exec, ${mpris_prev}"
        ", XF86AudioMute, Mute/Unmute Volume, exec, ${audio_mute}"
        ", XF86AudioMicMute, Mute/Unmute Microphone, exec, ${audio_micmute}"
      ]);
      binddel = mkForce (let
        increment_volume = dms' "audio increment 2";
        decrement_volume = dms' "audio decrement 2";
        brightness_up = dms' "brightness increment 5 \"amdgpu_bl2\"";
        brightness_down = dms' "brightness decrement 5 \"amdgpu_bl2\"";
      in [
        ", XF86AudioRaiseVolume, Increase Volume, exec, ${increment_volume}"
        ", XF86AudioLowerVolume, Decrease Volume, exec, ${decrement_volume}"
        ", XF86MonBrightnessUp, Increase Brightness, exec, ${brightness_up}"
        ", XF86MonBrightnessDown, Decrease Brightness, exec, ${brightness_down}"
      ]);
    };

    home.persistence."/persist".directories = [
      ".config/DankMaterialShell"
      ".local/state/DankMaterialShell"
      ".cache/DankMaterialShell"
      ".config/quickshell"
    ];
  };
}
