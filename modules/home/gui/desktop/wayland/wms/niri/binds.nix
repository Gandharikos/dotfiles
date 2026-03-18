{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.lists) foldl';
  inherit (lib.meta) getExe getExe';
  inherit (lib.modules) mkIf;
  inherit (lib.my) uwsmAppArgs;
  modNum = lib.trivial.mod;
  inherit (config.my.gui)
    desktop
    terminal
    browser
    fileManager
    ;

  cfg = config.my.gui.desktop.niri;
  inherit (desktop) mod;
  modShift = "${mod}+Shift";
  modCtrl = "${mod}+Ctrl";
  modAlt = "${mod}+Alt";

  numWorkspaces = desktop.workspace.number;
  workspaceNumbers = lib.genList (i: i + 1) numWorkspaces;
  workspaceKey = n: toString (modNum n 10);
  mkWorkspaceBinds =
    modifier: actionName: actionValueFn:
    builtins.listToAttrs (
      builtins.map (n: {
        name = "${modifier}+${workspaceKey n}";
        value = {
          action = {
            "${actionName}" = actionValueFn n;
          };
        };
      }) workspaceNumbers
    );

  playerctl = getExe pkgs.playerctl;
  wpctl = getExe' pkgs.wireplumber "wpctl";
  brightnessctl = getExe pkgs.brightnessctl;
  playerctlCmd = args: uwsmAppArgs pkgs playerctl args;
  wpctlCmd = args: uwsmAppArgs pkgs wpctl args;
  brightnessctlCmd = args: uwsmAppArgs pkgs brightnessctl args;
  dmsEnabled = config.programs.dank-material-shell.enable or false;
  noctaliaEnabled = config.programs.noctalia-shell.enable or false;
  shellHandlesXf86Binds = dmsEnabled || noctaliaEnabled;
  useNiriBuiltinShot = desktop.shot.default == "dank-material-shell" && !dmsEnabled;
  screenshotBinds =
    if useNiriBuiltinShot then
      {
        "Print".action.screenshot = [ ];
        "Shift+Print".action.screenshot-window.write-to-disk = true;
        "Ctrl+Print".action.screenshot-screen.write-to-disk = true;
        "${mod}+Print".action.screenshot = [ ];
      }
    else
      { };
  xf86FallbackBinds =
    if shellHandlesXf86Binds then
      { }
    else
      {
        "XF86AudioPlay" = {
          allow-when-locked = true;
          action.spawn = playerctlCmd [ "play-pause" ];
        };
        "XF86AudioPause" = {
          allow-when-locked = true;
          action.spawn = playerctlCmd [ "play-pause" ];
        };
        "XF86AudioNext" = {
          allow-when-locked = true;
          action.spawn = playerctlCmd [ "next" ];
        };
        "XF86AudioPrev" = {
          allow-when-locked = true;
          action.spawn = playerctlCmd [ "previous" ];
        };
        "XF86AudioMute" = {
          allow-when-locked = true;
          action.spawn = wpctlCmd [
            "set-mute"
            "@DEFAULT_AUDIO_SINK@"
            "toggle"
          ];
        };
        "XF86AudioMicMute" = {
          allow-when-locked = true;
          action.spawn = wpctlCmd [
            "set-mute"
            "@DEFAULT_AUDIO_SOURCE@"
            "toggle"
          ];
        };
        "XF86AudioRaiseVolume" = {
          allow-when-locked = true;
          repeat = true;
          action.spawn = wpctlCmd [
            "set-volume"
            "-l"
            "1.0"
            "@DEFAULT_AUDIO_SINK@"
            "6%+"
          ];
        };
        "XF86AudioLowerVolume" = {
          allow-when-locked = true;
          repeat = true;
          action.spawn = wpctlCmd [
            "set-volume"
            "-l"
            "1.0"
            "@DEFAULT_AUDIO_SINK@"
            "6%-"
          ];
        };
        "XF86MonBrightnessUp" = {
          allow-when-locked = true;
          repeat = true;
          action.spawn = brightnessctlCmd [
            "--exponent"
            "s"
            "5%+"
          ];
        };
        "XF86MonBrightnessDown" = {
          allow-when-locked = true;
          repeat = true;
          action.spawn = brightnessctlCmd [
            "--exponent"
            "s"
            "5%-"
          ];
        };
      };
in
with config.my.keyboard.keys;
{
  config = mkIf cfg.enable {
    programs.niri.settings = {
      screenshot-path = desktop.shot.path;

      binds = foldl' lib.attrsets.recursiveUpdate { } [
        {
          # Note: next-window and previous-window are not valid niri actions
          # Use Mod+Tab for toggle-overview instead, or focus-window-{up,down}
          "${mod}+Return" = {
            repeat = false;
            action.spawn = terminal.command;
          };
          "${mod}+B" = {
            repeat = false;
            action.spawn = browser.command;
          };
          "${mod}+${E}" = {
            repeat = false;
            action.spawn = fileManager.command;
          };
          "${mod}+Tab".action.toggle-overview = [ ];
          "${mod}+Q".action.close-window = [ ];
          "${mod}+Shift+Escape".action.quit.skip-confirmation = true;

          # Focus movement (Hyprland-like).
          "${mod}+${H}".action.focus-column-left = [ ];
          "${mod}+${L}".action.focus-column-right = [ ];
          "${mod}+${K}".action.focus-window-up = [ ];
          "${mod}+${J}".action.focus-window-down = [ ];

          # Move windows/columns.
          "${mod}+Shift+${H}".action.move-column-left = [ ];
          "${mod}+Shift+${L}".action.move-column-right = [ ];
          "${mod}+Shift+${K}".action.move-window-up = [ ];
          "${mod}+Shift+${J}".action.move-window-down = [ ];

          # Niri-specific column management.
          "${mod}+Ctrl+${H}".action.consume-or-expel-window-left = [ ];
          "${mod}+Ctrl+${L}".action.consume-or-expel-window-right = [ ];
          "${mod}+T".action.toggle-column-tabbed-display = [ ];

          # Floating / fullscreen.
          "${mod}+F".action.fullscreen-window = [ ];
          "${mod}+Shift+F".action.toggle-window-floating = [ ];
          "${mod}+M".action.maximize-column = [ ];
          "${mod}+C".action.center-column = [ ];
          "${mod}+R".action.switch-preset-column-width = [ ];
          "${mod}+Shift+R".action.switch-preset-window-height = [ ];
          "${mod}+Minus".action.set-column-width = "-10%";
          "${mod}+Equal".action.set-column-width = "+10%";

          # Monitor focus / move workspace.
          "${mod}+Comma".action.focus-monitor-left = [ ];
          "${mod}+Period".action.focus-monitor-right = [ ];
          "${mod}+Shift+Comma".action.move-workspace-to-monitor-left = [ ];
          "${mod}+Shift+Period".action.move-workspace-to-monitor-right = [ ];

          # Workspace navigation.
          "${mod}+BracketLeft".action.focus-workspace-up = [ ];
          "${mod}+BracketRight".action.focus-workspace-down = [ ];
          "${mod}+Shift+BracketLeft".action.move-column-to-workspace-up = [ ];
          "${mod}+Shift+BracketRight".action.move-column-to-workspace-down = [ ];
          "${mod}+Backspace".action.focus-workspace-up = [ ];

          # Hotkey overlay.
          "${mod}+Slash".action.show-hotkey-overlay = [ ];

          # Keyboard backlight.
          "XF86KbdBrightnessUp" = {
            allow-when-locked = true;
            repeat = true;
            action.spawn = brightnessctlCmd [
              "--device=*::kbd_backlight"
              "s"
              "10%+"
            ];
          };
          "XF86KbdBrightnessDown" = {
            allow-when-locked = true;
            repeat = true;
            action.spawn = brightnessctlCmd [
              "--device=*::kbd_backlight"
              "s"
              "10%-"
            ];
          };
        }
        screenshotBinds
        xf86FallbackBinds
        (mkWorkspaceBinds mod "focus-workspace" (n: n))
        (mkWorkspaceBinds modShift "move-window-to-workspace" (n: n))
        (mkWorkspaceBinds modCtrl "move-window-to-workspace" (n: [
          { focus = false; }
          n
        ]))
        (mkWorkspaceBinds modAlt "move-column-to-workspace" (n: n))
      ];
    };
  };
}
