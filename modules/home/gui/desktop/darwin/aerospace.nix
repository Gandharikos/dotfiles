{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.dot) mkAerospaceWorkspaces;
  inherit (config.dot) gui;
  cfg = gui.desktop;
  inherit (cfg.workspace) number;

  # Use modKey directly from config
  inherit (cfg) modKey; # Use as-is for "cmd-alt-ctrl" or other combinations
in
with config.dot.keyboard.keys;
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
              "${modKey}-space" = "layout tiles horizontal vertical";
              "${modKey}-shift-space" = "layout accordion horizontal vertical";

              # See: https://nikitabobko.github.io/AeroSpace/commands#focus
              "${modKey}-${h}" = "focus left";
              "${modKey}-${j}" = "focus down";
              "${modKey}-${k}" = "focus up";
              "${modKey}-${l}" = "focus right";

              # See: https://nikitabobko.github.io/AeroSpace/commands#move
              "${modKey}-shift-${h}" = "move left";
              "${modKey}-shift-${j}" = "move down";
              "${modKey}-shift-${k}" = "move up";
              "${modKey}-shift-${l}" = "move right";

              # See: https://nikitabobko.github.io/AeroSpace/commands#resize
              "${modKey}-shift-minus" = "resize smart -50";
              "${modKey}-shift-equal" = "resize smart +50";

              # fullscreen
              "${modKey}-f" = "fullscreen";
              # switch layout between tiling and floating
              "${modKey}-shift-f" = "layout floating tiling";

              # See: https://nikitabobko.github.io/AeroSpace/commands#workspace
              # "${modKey}-1" = "workspace 1";
              # "${modKey}-2" = "workspace 2";
              # "${modKey}-3" = "workspace 3";
              # "${modKey}-4" = "workspace 4";
              # "${modKey}-5" = "workspace 5";
              # "${modKey}-6" = "workspace 6";
              # "${modKey}-7" = "workspace 7";
              # "${modKey}-8" = "workspace 8";
              # "${modKey}-9" = "workspace 9";
              # "${modKey}-0" = "workspace 0";

              # See: https://nikitabobko.github.io/AeroSpace/commands#move-node-to-workspace
              # "${modKey}-shift-1" = "move-node-to-workspace 1";
              # "${modKey}-shift-2" = "move-node-to-workspace 2";
              # "${modKey}-shift-3" = "move-node-to-workspace 3";
              # "${modKey}-shift-4" = "move-node-to-workspace 4";
              # "${modKey}-shift-5" = "move-node-to-workspace 5";
              # "${modKey}-shift-6" = "move-node-to-workspace 6";
              # "${modKey}-shift-7" = "move-node-to-workspace 7";
              # "${modKey}-shift-8" = "move-node-to-workspace 8";
              # "${modKey}-shift-9" = "move-node-to-workspace 9";
              # "${modKey}-shift-0" = "move-node-to-workspace 0";

              # Custom shortcuts
              "${modKey}-enter" = "exec-and-forget open -n /applications/ghostty.app";

              # cmd-b = 'exec-and-forget open -n /Applications/Arc.app'
              "${modKey}-b" = "exec-and-forget open -a \"zen browser\"";

              # See: https://nikitabobko.github.io/AeroSpace/commands#workspace-back-and-forth
              "${modKey}-tab" = "workspace-back-and-forth";
              # See: https://nikitabobko.github.io/AeroSpace/commands#move-workspace-to-monitor
              "${modKey}-shift-tab" = "move-workspace-to-monitor --wrap-around next";

              "${modKey}-leftSquareBracket" = "workspace prev";
              "${modKey}-rightSquareBracket" = "workspace next";
              "${modKey}-shift-leftSquareBracket" = "move-node-to-workspace prev";
              "${modKey}-shift-rightSquareBracket" = "move-node-to-workspace next";

              "${modKey}-comma" = "focus-monitor left";
              "${modKey}-period" = "focus-monitor right";

              "${modKey}-shift-comma" = "move-node-to-monitor left";
              "${modKey}-shift-period" = "move-node-to-monitor right";
              # See: https://nikitabobko.github.io/AeroSpace/commands#mode
              "${modKey}-esc" = "mode service";

              "${modKey}-r" = "mode resize";

              "${modKey}-shift-r" = "reload-config";
            }
            // (mkAerospaceWorkspaces modKey number);
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
