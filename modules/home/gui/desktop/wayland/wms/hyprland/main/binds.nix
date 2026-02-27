{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.my) mkHyprWorkspaces mkHyprMoveTo;
  inherit (lib.lists) elem optionals;
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe getExe';
  inherit (config.my) desktop terminal browser fileManager;
  cfg = desktop.hyprland;
  num = desktop.general.workspace.number;
  mod = desktop.general.keybind.modifier;
  hyprsplit_enabled = cfg.plugins.enable && elem "hyprsplit" cfg.plugins.list;
  playerctl' = getExe pkgs.playerctl;
  wpctl' = getExe' pkgs.wireplumber "wpctl";
  brightnessctl' = getExe pkgs.brightnessctl;

  lang = "eng+chi_sim+chi_tra";
  wl-ocr = pkgs.writeShellScript "wl-ocr" ''
    ${getExe pkgs.grim} -g "$(${getExe pkgs.slurp})" - | ${getExe pkgs.tesseract} ${lang} - - | ${getExe' pkgs.wl-clipboard "wl-copy"}
  '';
in
  with config.my.keyboard.keys; {
    config = mkIf cfg.enable {
      wayland.windowManager.hyprland = {
        settings = {
          "$mod" = mod;
          # keybindings
          bindd =
            [
              # command
              "$mod SHIFT, Escape, Exit Hyprland, exit,"
              "$mod, Q, Close Window, killactive," # close the active window
              "$mod SHIFT, Q, Force Close Window, forcekillactive," # kill the active windwo
              "$mod, B, Launch Browser, exec, ${browser.exec}"
              "$mod, return, Launch Terminal, exec, ${terminal.exec}"
              "$mod, ${E}, Launch File Manager, exce, ${fileManager.exec}"

              # "$mod, space, exec, ags -t launcher"
              # "$mod SHIFT, R, exec, ags -q; ags"
              # "$mod, A, exec, ags -t overview"
              # "SUPER ALT, E,           exec, ags -r 'launcher.open(\":em \")'"
              # "SUPER ALT, V,           exec, ags -r 'launcher.open(\":ch \")'"
              # ",Print, exec, ags -r 'recorder.screenshot()'"
              # "$mod, Print, exec, ags -r 'recorder.screenshot(true)'"
              # "$mod ALT,Print, exec, ags -r 'recorder.start()'"
              # ",XF86PowerOff, exec, ags -t powermenu"
              # "$mod, U, exec, XDG_CURRENT_DESKTOP=GNOME gnome-control-center"

              "$mod, J, Toggle Split, togglesplit,"
              "$mod, Z, Bring to Top, alterzorder, top"
              "$mod SHIFT, Z, Send to Bottom, alterzorder, bottom"
              "$mod SHIFT, F, Toggle Floating, togglefloating,"
              "$mod, F, Fullscreen (Mode 0), fullscreen, 0"
              "$mod, M, Fullscreen (Mode 1), fullscreen, 1"
              "$mod, P, Toggle Pseudotile, pseudo,"
              "$mod SHIFT, P, Toggle Pin, pin,"
              # group
              "$mod, G, Toggle Group, togglegroup,"
              "$mod SHIFT, G, Next Group Window, changegroupactive, f"
              # move group
              "$mod SHIFT CONTROL, ${h}, Move Group Window Left, movewindoworgroUP, l"
              "$mod SHIFT CONTROL, ${j}, Move Group Window Down, movewindoworgroUP, d"
              "$mod SHIFT CONTROL, ${k}, Move Group Window Up, movewindoworgroUP, u"
              "$mod SHIFT CONTROL, ${l}, Move Group Window Right, movewindoworgroUP, r"
              # move focus
              "$mod, ${h}, Focus Left, movefocus, l"
              "$mod, ${j}, Focus Down, movefocus, d"
              "$mod, ${k}, Focus Up, movefocus, u"
              "$mod, ${l}, Focus Right, movefocus, r"
              # move window
              "$mod SHIFT, ${h}, Move Window Left, movewindow, l"
              "$mod SHIFT, ${j}, Move Window Down, movewindow, d"
              "$mod SHIFT, ${k}, Move Window Up, movewindow, u"
              "$mod SHIFT, ${l}, Move Window Right, movewindow, r"

              # special workspace
              "$mod SHIFT, grave, Toggle Special Workspace, togglespecialworkspace"
              "$mod, grave, Move to Special Workspace, movetoworkspace, special"
              "$mod CTRL, grave, Move to Special Workspace (Silent), movetoworkspacesilent, special"
              # monitors
              "$mod, comma, Focus Monitor Left, focusmonitor, l"
              "$mod, period, Focus Monitor Right, focusmonitor, r"
              "$mod SHIFT, comma, Move Workspace to Monitor Left, movecurrentworkspacetomonitor, l"
              "$mod SHIFT, period, Move Workspace to Monitor Right, movecurrentworkspacetomonitor, r"
              # workspace
              "$mod, W, Focus Empty Workspace, workspace, empty" # move to the first empty workspace
              # "$mod, tab, workspace, m+1"
              # "$mod SHIFT, tab, workspace, m-1"
              # send focused workspace to left/right monitor
              "$mod ALT, bracketleft, Move Workspace to Monitor Left, movecurrentworkspacetomonitor, l"
              "$mod ALT, bracketright, Move Workspace to Monitor Right, movecurrentworkspacetomonitor, r"
              # send focused workspace to left/right space silent
              "$mod CTRL, bracketleft, Move Window to Previous Workspace (Silent), movetoworkspacesilent, -1"
              "$mod CTRL, bracketright, Move Window to Next Workspace (Silent), movetoworkspacesilent, +1"

              # Workspace control
              "$mod, D, Focus Workspace D, focusworkspaceoncurrentmonitor, name:D" # desktop only
              "$mod, backspace, Focus Previous Workspace, focusworkspaceoncurrentmonitor, previous"

              "$mod, mouse_down, Previous Workspace, focusworkspaceoncurrentmonitor, -1"
              "$mod, mouse_up, Next Workspace, focusworkspaceoncurrentmonitor, +1"
              # utility
              # select area to perform OCR on
              "$mod, Print, OCR Selection, exec, ${wl-ocr}"
              ", XF86Favorites, OCR Selection, exec, ${wl-ocr}"
            ]
            ++ (mkHyprMoveTo ["focusworkspaceoncurrentmonitor" "movetoworkspacesilent"] num)
            ++ (optionals (!hyprsplit_enabled)
              (mkHyprWorkspaces
                ["workspace" "movetoworkspace" "movetoworkspacesilent"]
                num))
            ++ (optionals (!cfg.switch.enable) [
              "ALT, tab, Cycle Next Window, cyclenext,"
              "ALT SHIFT, tab, Bring Active to Top, bringactivetotop,"
            ])
            ++ (optionals (!cfg.nome.enable) [
              "$mod, mouse_down, Next Workspace, workspace, e+1"
              "$mod, mouse_up, Previous Workspace, workspace, e-1"
              "$mod, bracketleft, Next Workspace, workspace, e+1"
              "$mod, bracketright, Previous Workspace, workspace, e-1"
              "$mod SHIFT, bracketleft, Move Window to Previous Workspace, movetoworkspace, -1"
              "$mod SHIFT, bracketright, Move Window to Next Workspace, movetoworkspace, +1"
            ]);

          # Bind: mouse binds
          binddm = [
            # Move/resize windows with mainMod + LMB/RMB and dragging
            "$mod, mouse:272, Move Window, movewindow"
            "$mod ALT, mouse:272, Resize Window, resizewindow"
          ];

          # Bind: repeat while holding
          bindde = [
            # Window split ratio
            "$mod, Minus, Decrease Split Ratio, splitratio, -0.1"
            "$mod, Equal, Increase Split Ratio, splitratio, 0.1"
            "$mod, Semicolon, Decrease Split Ratio, splitratio, -0.1"
            "$mod, Apostrophe, Increase Split Ratio, splitratio, 0.1"
            # resizing the active window
            "$mod CTRL, ${h}, Resize Window Left, resizeactive, 10 0"
            "$mod CTRL, ${j}, Resize Window Down, resizeactive, 0 10"
            "$mod CTRL, ${k}, Resize Window Up, resizeactive, 0 -10"
            "$mod CTRL, ${l}, Resize Window Right, resizeactive, -10 0"
          ];

          # Bind: locked binds
          binddl = [
            # media controls
            ", XF86AudioPlay, Play, exec, ${playerctl'} play"
            ", XF86AudioPrev, Previous Track, exec, ${playerctl'} previous"
            ", XF86AudioNext, Next Track, exec, ${playerctl'} next"
            ", XF86AudioPause, Pause, exec, ${playerctl'} pause"

            # volume
            ", XF86AudioMute, Mute Audio, exec, ${wpctl'} set-mute @DEFAULT_AUDIO_SINK@ toggle"
            ", XF86AudioMicMute, Mute Microphone, exec, ${wpctl'} set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

            # misc
            ", XF86Messenger, Toggle Special Workspace, togglespecialworkspace"
          ];

          # Bind: locked and repeat
          binddel = [
            # volume
            ", XF86AudioRaiseVolume, Volume Up, exec, ${wpctl'} set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 6%+"
            ", XF86AudioLowerVolume, Volume Down, exec, ${wpctl'} set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 6%-"
            "ALT, XF86AudioRaiseVolume, Mic Volume Up, exec, ${wpctl'} set-volume -l '1.0' @DEFAULT_AUDIO_SOURCE@ 6%+"
            "ALT, XF86AudioLowerVolume, Mic Volume Down, exec, ${wpctl'} set-volume -l '1.0' @DEFAULT_AUDIO_SOURCE@ 6%-"

            # backlight
            ", XF86MonBrightnessUp, Brightness Up, exec, ${brightnessctl'} --exponent s 5%+"
            ", XF86MonBrightnessDown, Brightness Down, exec, ${brightnessctl'} --exponent s 5%-"
            ", XF86KbdBrightnessUp, Keyboard Brightness Up, exec, ${brightnessctl'} --device='*::kbd_backlight' s 10%+"
            ", XF86KbdBrightnessDown, Keyboard Brightness Down, exec, ${brightnessctl'} --device='*::kbd_backlight' s 10%-"
          ];
        };
        extraConfig = ''
          # window resize
          bind=$mod,R,submap,resize

          submap=resize
          binde=,${h},resizeactive,10 0
          binde=,${j},resizeactive,0 10
          binde=,${k},resizeactive,0 -10
          binde=,${l},resizeactive,-10 0

          binde=,right,resizeactive,10 0
          binde=,left,resizeactive,-10 0
          binde=,up,resizeactive,0 -10
          binde=,down,resizeactive,0 10


          binde=SHIFT,${h},moveactive,-10 0
          binde=SHIFT,${j},moveactive,0 10
          binde=SHIFT,${k},moveactive,0 -10
          binde=SHIFT,${l},moveactive,10 0

          binde=SHIFT,right,moveactive,10 0
          binde=SHIFT,left,moveactive,-10 0
          binde=SHIFT,up,moveactive,0 -10
          binde=SHIFT,down,moveactive,0 10

          bind = , SPACE, centerwindow

          bind = , escape, exec, hyprctl keyword input:follow_mouse 0
          bind=,escape,submap,reset
          submap=reset
        '';
      };
    };
  }
