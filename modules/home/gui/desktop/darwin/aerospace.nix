{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.my) mkAerospaceWorkspaces;
  inherit (config.my) gui;
  cfg = gui.desktop;
  inherit (cfg.workspace) number;

  # Use mod directly from config
  inherit (cfg) mod; # Use as-is for "cmd-alt-ctrl" or other combinations
in
with config.my.keyboard.keys;
{
  config = mkIf (gui.enable && cfg.type == "darwin" && cfg.default == "aerospace") {
    programs.aerospace = {
      enable = true;
      launchd.enable = true;
      settings = {
        # You can use it to add commands that run after login to macOS user session.
        # 'start-at-login' needs to be 'true' for 'after-login-command' to work
        # Available commands: https://nikitabobko.github.io/AeroSpace/commands
        after-login-command = [ ];

        # You can use it to add commands that run after AeroSpace startup.
        # 'after-startup-command' is run after 'after-login-command'
        # Available commands : https://nikitabobko.github.io/AeroSpace/commands
        after-startup-command = [ ];

        # Start Aerospace at login
        start-at-login = true;

        # Normalizations. See: https://nikitabobko.github.io/AeroSpace/guide#normalization
        enable-normalization-flatten-containers = true;
        enable-normalization-opposite-orientation-for-nested-containers = true;

        # See: https://nikitabobko.github.io/AeroSpace/guide#layouts
        # The 'accordion-padding' specifies the size of accordion padding
        # You can set 0 to disable the padding feature
        accordion-padding = 30;

        # Possible values: tiles|accordion
        default-root-container-layout = "tiles";

        # Possible values: horizontal|vertical|auto
        # 'auto' means: wide monitor (anything wider than high) gets horizontal orientation,
        #               tall monitor (anything higher than wide) gets vertical orientation
        default-root-container-orientation = "auto";

        # Possible values: (qwerty|dvorak)
        # See https://nikitabobko.github.io/AeroSpace/guide#key-mapping
        key-mapping.preset = "qwerty";

        # Mouse follows focus when focused monitor changes
        # Drop it from your config, if you don't like this behavior
        # See https://nikitabobko.github.io/AeroSpace/guide#on-focus-changed-callbacks
        # See https://nikitabobko.github.io/AeroSpace/commands#move-mouse
        # Fallback value (if you omit the key): on-focused-monitor-changed = []
        on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

        # Gaps configuration
        gaps = {
          inner = {
            horizontal = 10;
            vertical = 10;
          };
          outer = {
            left = 5;
            bottom = 5;
            top = 5;
            right = 5;
          };
        };

        exec = {
          inherit-env-vars = true;
          env-vars = {
            # You can add environment variables here
            # Example:
            # "MY_VAR" = "my_value";
            PATH = "/opt/homebrew/bin:/opt/homebrew/sbin:$\{PATH\}";
          };
        };

        mode = {
          main = {
            binding = {
              # See: https://nikitabobko.github.io/AeroSpace/commands#layout
              "${mod}-space" = "layout tiles horizontal vertical";
              "${mod}-shift-space" = "layout accordion horizontal vertical";

              # See: https://nikitabobko.github.io/AeroSpace/commands#focus
              "${mod}-${h}" = "focus left";
              "${mod}-${j}" = "focus down";
              "${mod}-${k}" = "focus up";
              "${mod}-${l}" = "focus right";

              # See: https://nikitabobko.github.io/AeroSpace/commands#move
              "${mod}-shift-${h}" = "move left";
              "${mod}-shift-${j}" = "move down";
              "${mod}-shift-${k}" = "move up";
              "${mod}-shift-${l}" = "move right";

              # See: https://nikitabobko.github.io/AeroSpace/commands#resize
              "${mod}-shift-minus" = "resize smart -50";
              "${mod}-shift-equal" = "resize smart +50";

              # fullscreen
              "${mod}-f" = "fullscreen";
              # switch layout between tiling and floating
              "${mod}-shift-f" = "layout floating tiling";

              # See: https://nikitabobko.github.io/AeroSpace/commands#workspace
              # "${mod}-1" = "workspace 1";
              # "${mod}-2" = "workspace 2";
              # "${mod}-3" = "workspace 3";
              # "${mod}-4" = "workspace 4";
              # "${mod}-5" = "workspace 5";
              # "${mod}-6" = "workspace 6";
              # "${mod}-7" = "workspace 7";
              # "${mod}-8" = "workspace 8";
              # "${mod}-9" = "workspace 9";
              # "${mod}-0" = "workspace 0";

              # See: https://nikitabobko.github.io/AeroSpace/commands#move-node-to-workspace
              # "${mod}-shift-1" = "move-node-to-workspace 1";
              # "${mod}-shift-2" = "move-node-to-workspace 2";
              # "${mod}-shift-3" = "move-node-to-workspace 3";
              # "${mod}-shift-4" = "move-node-to-workspace 4";
              # "${mod}-shift-5" = "move-node-to-workspace 5";
              # "${mod}-shift-6" = "move-node-to-workspace 6";
              # "${mod}-shift-7" = "move-node-to-workspace 7";
              # "${mod}-shift-8" = "move-node-to-workspace 8";
              # "${mod}-shift-9" = "move-node-to-workspace 9";
              # "${mod}-shift-0" = "move-node-to-workspace 0";

              # Custom shortcuts
              "${mod}-enter" = "exec-and-forget open -n /applications/ghostty.app";

              # cmd-b = 'exec-and-forget open -n /Applications/Arc.app'
              "${mod}-b" = "exec-and-forget open -a \"zen browser\"";

              # See: https://nikitabobko.github.io/AeroSpace/commands#workspace-back-and-forth
              "${mod}-tab" = "workspace-back-and-forth";
              # See: https://nikitabobko.github.io/AeroSpace/commands#move-workspace-to-monitor
              "${mod}-shift-tab" = "move-workspace-to-monitor --wrap-around next";

              "${mod}-leftSquareBracket" = "workspace prev";
              "${mod}-rightSquareBracket" = "workspace next";
              "${mod}-shift-leftSquareBracket" = "move-node-to-workspace prev";
              "${mod}-shift-rightSquareBracket" = "move-node-to-workspace next";

              "${mod}-comma" = "focus-monitor left";
              "${mod}-period" = "focus-monitor right";

              "${mod}-shift-comma" = "move-node-to-monitor left";
              "${mod}-shift-period" = "move-node-to-monitor right";
              # See: https://nikitabobko.github.io/AeroSpace/commands#mode
              "${mod}-esc" = "mode service";

              "${mod}-r" = "mode resize";

              "${mod}-shift-r" = "reload-config";
            }
            // (mkAerospaceWorkspaces hyper number);
          };
          resize = {
            binding = {
              "${h}" = "resize width +50";
              "${j}" = "resize height -50";
              "${k}" = "resize height +50";
              "${l}" = "resize width -50";
              "minus" = "resize smart -50";
              "equal" = "resize smart +50";
              "enter" = "mode main";
              "esc" = "mode main";
            };
          };
          service = {
            binding = {
              "esc" = [
                "reload-config"
                "mode main"
              ];
              "r" = [
                "flatten-workspace-tree"
                "mode main"
              ]; # reset layout
              "f" = [
                "layout floating tiling"
                "mode main"
              ]; # Toggle between floating and tiling layout
              "backspace" = [
                "close-all-windows-but-current"
                "mode main"
              ];
              "${h}" = [
                "join-with left"
                "mode main"
              ];
              "${j}" = [
                "join-with down"
                "mode main"
              ];
              "${k}" = [
                "join-with up"
                "mode main"
              ];
              "${l}" = [
                "join-with right"
                "mode main"
              ];

              # sticky is not yet supported https://github.com/nikitabobko/AeroSpace/issues/2
              #s = ['layout sticky tiling', 'mode main']
              "down" = "volume down";
              "up" = "volume up";
              "shift-down" = [
                "volume set 0"
                "mode main"
              ];
            };
          };
        };
        on-window-detected = [
          {
            "if" = {
              app-id = "org.mozilla.com.zen.browser";
              window-title-regex-substring = "picture-in-picture";
            };
            run = "move-node-to-workspace 1";
          }
          {
            "if" = {
              app-id = "com.mitchellh.ghostty";
            };
            run = "move-node-to-workspace 1";
          }
          {
            "if" = {
              app-id = "company.thebrowser.Browser";
            };
            run = "move-node-to-workspace 1";
          }
          {
            "if" = {
              app-id = "com.microsoft.VSCode";
            };
            run = "move-node-to-workspace 1";
          }
          {
            "if" = {
              app-id = "com.tencent.xinWeChat";
            };
            run = "move-node-to-workspace 2";
          }
          {
            "if" = {
              app-id = "com.tencent.qq";
            };
            run = "move-node-to-workspace 2";
          }
          {
            "if" = {
              app-id = "com.spotify.client";
            };
            run = "move-node-to-workspace 4";
          }
          {
            "if" = {
              app-id = "com.hnc.Discord";
            };
            run = "move-node-to-workspace 4";
          }
          {
            "if" = {
              app-id = "ru.keepcoder.Telegram";
            };
            run = "move-node-to-workspace 4";
          }
        ];

        # Monitor assignments
        workspace-to-monitor-force-assignment = {
          "1" = "main";
          "2" = [
            "secondary"
            "main"
          ];
          "3" = "main";
          "4" = [
            "secondary"
            "main"
          ];
          "5" = "main";
          "6" = [
            "secondary"
            "main"
          ];
          "7" = "main";
          "8" = [
            "secondary"
            "main"
          ];
          "9" = "main";
          "10" = [
            "secondary"
            "main"
          ];
        };
      };
    };
  };
}
