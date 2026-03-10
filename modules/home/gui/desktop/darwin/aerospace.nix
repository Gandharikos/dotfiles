{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.my) mkAerospaceWorkspaces;
  cfg = config.my.gui.desktop;
  inherit (cfg.general.workspace) number;
  hyper = "cmd-alt-ctrl";
in
  with config.my.keyboard.keys; {
    config = mkIf (cfg.enable && cfg.type == "darwin" && cfg.default == "aerospace") {
      programs.aerospace = {
        enable = true;
        launchd.enable = true;
        settings = {
          # You can use it to add commands that run after login to macOS user session.
          # 'start-at-login' needs to be 'true' for 'after-login-command' to work
          # Available commands: https://nikitabobko.github.io/AeroSpace/commands
          after-login-command = [];

          # You can use it to add commands that run after AeroSpace startup.
          # 'after-startup-command' is run after 'after-login-command'
          # Available commands : https://nikitabobko.github.io/AeroSpace/commands
          after-startup-command = [];

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
          on-focused-monitor-changed = ["move-mouse monitor-lazy-center"];

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
              binding =
                {
                  # See: https://nikitabobko.github.io/AeroSpace/commands#layout
                  "${hyper}-space" = "layout tiles horizontal vertical";
                  "${hyper}-shift-space" = "layout accordion horizontal vertical";

                  # See: https://nikitabobko.github.io/AeroSpace/commands#focus
                  "${hyper}-${h}" = "focus left";
                  "${hyper}-${j}" = "focus down";
                  "${hyper}-${k}" = "focus up";
                  "${hyper}-${l}" = "focus right";

                  # See: https://nikitabobko.github.io/AeroSpace/commands#move
                  "${hyper}-shift-${h}" = "move left";
                  "${hyper}-shift-${j}" = "move down";
                  "${hyper}-shift-${k}" = "move up";
                  "${hyper}-shift-${l}" = "move right";

                  # See: https://nikitabobko.github.io/AeroSpace/commands#resize
                  "${hyper}-shift-minus" = "resize smart -50";
                  "${hyper}-shift-equal" = "resize smart +50";

                  # fullscreen
                  "${hyper}-f" = "fullscreen";
                  # switch layout between tiling and floating
                  "${hyper}-shift-f" = "layout floating tiling";

                  # See: https://nikitabobko.github.io/AeroSpace/commands#workspace
                  # "${hyper}-1" = "workspace 1";
                  # "${hyper}-2" = "workspace 2";
                  # "${hyper}-3" = "workspace 3";
                  # "${hyper}-4" = "workspace 4";
                  # "${hyper}-5" = "workspace 5";
                  # "${hyper}-6" = "workspace 6";
                  # "${hyper}-7" = "workspace 7";
                  # "${hyper}-8" = "workspace 8";
                  # "${hyper}-9" = "workspace 9";
                  # "${hyper}-0" = "workspace 0";

                  # See: https://nikitabobko.github.io/AeroSpace/commands#move-node-to-workspace
                  # "${hyper}-shift-1" = "move-node-to-workspace 1";
                  # "${hyper}-shift-2" = "move-node-to-workspace 2";
                  # "${hyper}-shift-3" = "move-node-to-workspace 3";
                  # "${hyper}-shift-4" = "move-node-to-workspace 4";
                  # "${hyper}-shift-5" = "move-node-to-workspace 5";
                  # "${hyper}-shift-6" = "move-node-to-workspace 6";
                  # "${hyper}-shift-7" = "move-node-to-workspace 7";
                  # "${hyper}-shift-8" = "move-node-to-workspace 8";
                  # "${hyper}-shift-9" = "move-node-to-workspace 9";
                  # "${hyper}-shift-0" = "move-node-to-workspace 0";

                  # Custom shortcuts
                  "${hyper}-enter" = "exec-and-forget open -n /applications/ghostty.app";

                  # cmd-b = 'exec-and-forget open -n /Applications/Arc.app'
                  "${hyper}-b" = "exec-and-forget open -a \"zen browser\"";

                  # See: https://nikitabobko.github.io/AeroSpace/commands#workspace-back-and-forth
                  "${hyper}-tab" = "workspace-back-and-forth";
                  # See: https://nikitabobko.github.io/AeroSpace/commands#move-workspace-to-monitor
                  "${hyper}-shift-tab" = "move-workspace-to-monitor --wrap-around next";

                  "${hyper}-leftSquareBracket" = "workspace prev";
                  "${hyper}-rightSquareBracket" = "workspace next";
                  "${hyper}-shift-leftSquareBracket" = "move-node-to-workspace prev";
                  "${hyper}-shift-rightSquareBracket" = "move-node-to-workspace next";

                  "${hyper}-comma" = "focus-monitor left";
                  "${hyper}-period" = "focus-monitor right";

                  "${hyper}-shift-comma" = "move-node-to-monitor left";
                  "${hyper}-shift-period" = "move-node-to-monitor right";
                  # See: https://nikitabobko.github.io/AeroSpace/commands#mode
                  "${hyper}-esc" = "mode service";

                  "${hyper}-r" = "mode resize";

                  "${hyper}-shift-r" = "reload-config";
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
                "esc" = ["reload-config" "mode main"];
                "r" = ["flatten-workspace-tree" "mode main"]; # reset layout
                "f" = [
                  "layout floating tiling"
                  "mode main"
                ]; # Toggle between floating and tiling layout
                "backspace" = ["close-all-windows-but-current" "mode main"];
                "${h}" = ["join-with left" "mode main"];
                "${j}" = ["join-with down" "mode main"];
                "${k}" = ["join-with up" "mode main"];
                "${l}" = ["join-with right" "mode main"];

                # sticky is not yet supported https://github.com/nikitabobko/AeroSpace/issues/2
                #s = ['layout sticky tiling', 'mode main']
                "down" = "volume down";
                "up" = "volume up";
                "shift-down" = ["volume set 0" "mode main"];
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
            "2" = ["secondary" "main"];
            "3" = "main";
            "4" = ["secondary" "main"];
            "5" = "main";
            "6" = ["secondary" "main"];
            "7" = "main";
            "8" = ["secondary" "main"];
            "9" = "main";
            "10" = ["secondary" "main"];
          };
        };
      };
    };
  }
