{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.lists) foldl';
  inherit (lib.meta) getExe getExe';
  inherit (lib.modules) mkIf;
  inherit (lib.trivial) mod;
  inherit (config.my) desktop terminal browser;
  inherit (config.xdg.userDirs.extraConfig) SCREENSHOTS;

  cfg = config.my.desktop.niri;

  modKey =
    if desktop.general.keybind.modifier == "SUPER"
    then "Mod"
    else if desktop.general.keybind.modifier == "CTRL"
    then "Ctrl"
    else "Alt";
  modShift = "${modKey}+Shift";
  modCtrl = "${modKey}+Ctrl";
  modAlt = "${modKey}+Alt";

  numWorkspaces = desktop.general.workspace.number;
  workspaceNumbers = lib.genList (i: i + 1) numWorkspaces;
  workspaceKey = n: toString (mod n 10);
  mkWorkspaceBinds = modifier: actionName: actionValueFn:
    builtins.listToAttrs (
      builtins.map (n: {
        name = "${modifier}+${workspaceKey n}";
        value = {action = {"${actionName}" = actionValueFn n;};};
      })
      workspaceNumbers
    );

  playerctl = getExe pkgs.playerctl;
  wpctl = getExe' pkgs.wireplumber "wpctl";
  brightnessctl = getExe pkgs.brightnessctl;

  hyprlock = getExe pkgs.hyprlock;

  screenshotPath = "${SCREENSHOTS}/screenshot-%Y%m%d-%H%M%S.png";
  dmsEnabled = config.programs.dank-material-shell.enable or false;
  useDmsShot = desktop.shot == "dms" && dmsEnabled;
  screenshotBinds =
    if useDmsShot
    then {}
    else {
      "Print".action.screenshot = [];
      "Shift+Print".action.screenshot-window.write-to-disk = true;
      "Ctrl+Print".action.screenshot-screen.write-to-disk = true;
      "${modKey}+Print".action.screenshot = [];
    };
  xf86FallbackBinds =
    if dmsEnabled
    then {}
    else {
      "XF86AudioPlay" = {
        allow-when-locked = true;
        action.spawn = [playerctl "play-pause"];
      };
      "XF86AudioPause" = {
        allow-when-locked = true;
        action.spawn = [playerctl "play-pause"];
      };
      "XF86AudioNext" = {
        allow-when-locked = true;
        action.spawn = [playerctl "next"];
      };
      "XF86AudioPrev" = {
        allow-when-locked = true;
        action.spawn = [playerctl "previous"];
      };
      "XF86AudioMute" = {
        allow-when-locked = true;
        action.spawn = [wpctl "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"];
      };
      "XF86AudioMicMute" = {
        allow-when-locked = true;
        action.spawn = [wpctl "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"];
      };
      "XF86AudioRaiseVolume" = {
        allow-when-locked = true;
        repeat = true;
        action.spawn = [wpctl "set-volume" "-l" "1.0" "@DEFAULT_AUDIO_SINK@" "6%+"];
      };
      "XF86AudioLowerVolume" = {
        allow-when-locked = true;
        repeat = true;
        action.spawn = [wpctl "set-volume" "-l" "1.0" "@DEFAULT_AUDIO_SINK@" "6%-"];
      };
      "XF86MonBrightnessUp" = {
        allow-when-locked = true;
        repeat = true;
        action.spawn = [brightnessctl "--exponent" "s" "5%+"];
      };
      "XF86MonBrightnessDown" = {
        allow-when-locked = true;
        repeat = true;
        action.spawn = [brightnessctl "--exponent" "s" "5%-"];
      };
    };

  lockBinds =
    if desktop.lock == "hyprlock"
    then {
      "${modKey}+Alt+L".action.spawn = hyprlock;
    }
    else {};
in
  with config.my.keyboard.keys; {
    imports = [inputs.niri.homeModules.niri];

    config = mkIf cfg.enable {
      programs.niri.settings = {
        screenshot-path = screenshotPath;

        recent-windows = {
          binds = {
            "Alt+Tab".action.next-window = [];
            "Alt+Shift+Tab".action.previous-window = [];
          };
        };

        binds = foldl' lib.attrsets.recursiveUpdate {} [
          {
            "${modKey}+Return" = {
              repeat = false;
              action.spawn = terminal.exec;
            };
            "${modKey}+B" = {
              repeat = false;
              action.spawn = browser.exec;
            };
            "${modKey}+Tab".action.toggle-overview = [];
            "${modKey}+Q".action.close-window = [];
            "${modKey}+Shift+Escape".action.quit.skip-confirmation = true;

            # Focus movement (Hyprland-like).
            "${modKey}+${H}".action.focus-column-left = [];
            "${modKey}+${L}".action.focus-column-right = [];
            "${modKey}+${K}".action.focus-window-up = [];
            "${modKey}+${J}".action.focus-window-down = [];

            # Move windows/columns.
            "${modKey}+Shift+${H}".action.move-column-left = [];
            "${modKey}+Shift+${L}".action.move-column-right = [];
            "${modKey}+Shift+${K}".action.move-window-up = [];
            "${modKey}+Shift+${J}".action.move-window-down = [];

            # Niri-specific column management.
            "${modKey}+Ctrl+${H}".action.consume-or-expel-window-left = [];
            "${modKey}+Ctrl+${L}".action.consume-or-expel-window-right = [];
            "${modKey}+T".action.toggle-column-tabbed-display = [];

            # Floating / fullscreen.
            "${modKey}+F".action.fullscreen-window = [];
            "${modKey}+Shift+F".action.toggle-window-floating = [];
            "${modKey}+M".action.maximize-column = [];

            # Monitor focus / move workspace.
            "${modKey}+Comma".action.focus-monitor-left = [];
            "${modKey}+Period".action.focus-monitor-right = [];
            "${modKey}+Shift+Comma".action.move-workspace-to-monitor-left = [];
            "${modKey}+Shift+Period".action.move-workspace-to-monitor-right = [];

            # Workspace navigation.
            "${modKey}+BracketLeft".action.focus-workspace-up = [];
            "${modKey}+BracketRight".action.focus-workspace-down = [];
            "${modKey}+Shift+BracketLeft".action.move-column-to-workspace-up = [];
            "${modKey}+Shift+BracketRight".action.move-column-to-workspace-down = [];
            "${modKey}+Backspace".action.focus-workspace-up = [];

            # Hotkey overlay.
            "${modKey}+Slash".action.show-hotkey-overlay = [];

            # Keyboard backlight.
            "XF86KbdBrightnessUp" = {
              allow-when-locked = true;
              repeat = true;
              action.spawn = [brightnessctl "--device=*::kbd_backlight" "s" "10%+"];
            };
            "XF86KbdBrightnessDown" = {
              allow-when-locked = true;
              repeat = true;
              action.spawn = [brightnessctl "--device=*::kbd_backlight" "s" "10%-"];
            };
          }
          lockBinds
          screenshotBinds
          xf86FallbackBinds
          (mkWorkspaceBinds modKey "focus-workspace" (n: n))
          (mkWorkspaceBinds modShift "move-window-to-workspace" (n: n))
          (mkWorkspaceBinds modCtrl "move-window-to-workspace" (n: [
            {focus = false;}
            n
          ]))
          (mkWorkspaceBinds modAlt "move-column-to-workspace" (n: n))
        ];
      };
    };
  }
