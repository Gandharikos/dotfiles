{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf mkBefore;
  cfg = config.my.herdr;
  autoStart = config.my.mux.autoStart && config.my.mux.default == "herdr";
  herdr = lib.getExe pkgs.herdr;
  backend = pkgs.vimPlugins.smart-splits-backend-herdr.src;
  smartQuit = pkgs.writeShellApplication {
    name = "herdr-smart-quit";
    runtimeInputs = [
      pkgs.herdr
      pkgs.jq
    ];
    text = builtins.readFile (lib.dot.relativeToRoot "scripts/herdr-smart-quit.sh");
  };
in
{
  options.my.herdr = {
    enable = mkEnableOption "herdr terminal workspace manager for AI coding agents" // {
      default = config.my.mux.default == "herdr";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [
        pkgs.jq
        smartQuit
      ];
      activation.herdrSmartSplits = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        run ${herdr} plugin link ${backend} --enabled >/dev/null
      '';
    };

    programs = {
      fish.interactiveShellInit = mkIf autoStart ''
        if not set -q HERDR_ENV
           and not set -q HC_TERMINAL_ID
           and not set -q TMUX
           and test -z "$ZELLIJ_SESSION_NAME"
           and test -z "$REX_SESSION"
           and test -z "$SSH_TTY"
           and test -z "$SSH_CONNECTION"
           and test -z "$SSH_CLIENT"
           and test -z "$WSL_DISTRO_NAME"
           and test -z "$INSIDE_EMACS"
           and test -z "$EMACS"
           and test -z "$VIM"
           and test -z "$NVIM"
           and test -z "$INSIDE_PYCHARM"
           and test -z "$ZED_TERMINAL"
           and test "$TERM_PROGRAM" != "rex"
           and test "$TERM_PROGRAM" != "vscode"
           and test -t 0
          ${herdr}
        end
      '';

      bash.initExtra = mkIf autoStart ''
        if [[ $- == *i* && -t 0 && -z "$HERDR_ENV" && -z "$HC_TERMINAL_ID" && -z "$TMUX" \
          && -z "$ZELLIJ_SESSION_NAME" && -z "$REX_SESSION" \
          && -z "$SSH_TTY" && -z "$SSH_CONNECTION" && -z "$SSH_CLIENT" \
          && -z "$WSL_DISTRO_NAME" && -z "$INSIDE_EMACS" && -z "$EMACS" \
          && -z "$VIM" && -z "$NVIM" && -z "$INSIDE_PYCHARM" \
          && -z "$ZED_TERMINAL" && "$TERM_PROGRAM" != "rex" \
          && "$TERM_PROGRAM" != "vscode" ]]; then
          ${herdr}
        fi
      '';

      zsh.initContent = mkIf autoStart (mkBefore ''
        if [[ -o interactive && -t 0 && -z "$HERDR_ENV" && -z "$HC_TERMINAL_ID" && -z "$TMUX" \
          && -z "$ZELLIJ_SESSION_NAME" && -z "$REX_SESSION" \
          && -z "$SSH_TTY" && -z "$SSH_CONNECTION" && -z "$SSH_CLIENT" \
          && -z "$WSL_DISTRO_NAME" && -z "$INSIDE_EMACS" && -z "$EMACS" \
          && -z "$VIM" && -z "$NVIM" && -z "$INSIDE_PYCHARM" \
          && -z "$ZED_TERMINAL" && "$TERM_PROGRAM" != "rex" \
          && "$TERM_PROGRAM" != "vscode" ]]; then
          ${herdr}
        fi
      '');

      nushell.extraConfig = mkIf autoStart ''
        if (
          $nu.is-interactive
          and (($env.HERDR_ENV? | default "") | is-empty)
          and (($env.HC_TERMINAL_ID? | default "") | is-empty)
          and (($env.TMUX? | default "") | is-empty)
          and (($env.ZELLIJ_SESSION_NAME? | default "") | is-empty)
          and (($env.REX_SESSION? | default "") | is-empty)
          and (($env.SSH_TTY? | default "") | is-empty)
          and (($env.SSH_CONNECTION? | default "") | is-empty)
          and (($env.SSH_CLIENT? | default "") | is-empty)
          and (($env.WSL_DISTRO_NAME? | default "") | is-empty)
          and (($env.INSIDE_EMACS? | default "") | is-empty)
          and (($env.EMACS? | default "") | is-empty)
          and (($env.VIM? | default "") | is-empty)
          and (($env.NVIM? | default "") | is-empty)
          and (($env.INSIDE_PYCHARM? | default "") | is-empty)
          and (($env.ZED_TERMINAL? | default "") | is-empty)
          and (($env.TERM_PROGRAM? | default "") != "rex")
          and (($env.TERM_PROGRAM? | default "") != "vscode")
        ) {
          ${herdr}
        }
      '';

      herdr = {
        enable = true;
        package = pkgs.herdr;
        settings = {
          onboarding = false;

          keys = {
            prefix = "ctrl+a";
            detach = "prefix+d";
            reload_config = "prefix+ctrl+r";
            settings = "prefix+comma";
            workspace_picker = "prefix+s";
            goto = "prefix+w";
            close_workspace = "prefix+shift+q";
            new_tab = "prefix+t";
            close_tab = "prefix+q";
            previous_tab = "prefix+[";
            next_tab = "prefix+]";
            move_tab_previous = "prefix+shift+[";
            move_tab_next = "prefix+shift+]";
            copy_mode = "prefix+esc";
            cycle_pane_previous = "prefix+minus";
            cycle_pane_next = [
              "prefix+p"
              "prefix+="
            ];
            toggle_sidebar = [
              "prefix+b"
              "prefix+slash"
            ];
            focus_pane_left = "prefix+left";
            focus_pane_down = "prefix+down";
            focus_pane_up = "prefix+up";
            focus_pane_right = "prefix+right";
            split_vertical = "prefix+${osConfig.dot.keyboard.keys.l}";
            split_horizontal = "prefix+${osConfig.dot.keyboard.keys.j}";
            command = with osConfig.dot.keyboard.keys; [
              {
                key = "ctrl+q";
                type = "shell";
                command = lib.getExe smartQuit;
                description = "smart quit (vim/herdr)";
              }
              {
                key = "ctrl+${h}";
                type = "plugin_action";
                command = "smart-splits-backend-herdr.left";
                description = "navigate left (neovim/herdr)";
              }
              {
                key = "ctrl+${j}";
                type = "plugin_action";
                command = "smart-splits-backend-herdr.down";
                description = "navigate down (neovim/herdr)";
              }
              {
                key = "ctrl+${k}";
                type = "plugin_action";
                command = "smart-splits-backend-herdr.up";
                description = "navigate up (neovim/herdr)";
              }
              {
                key = "ctrl+${l}";
                type = "plugin_action";
                command = "smart-splits-backend-herdr.right";
                description = "navigate right (neovim/herdr)";
              }
            ];
          };

          terminal = {
            shell_mode = "auto";
            new_cwd = "follow";
          };

          update = {
            channel = "stable";
            version_check = false;
            manifest_check = true;
          };

          ui = {
            mouse_capture = true;
            pane_borders = true;
            pane_gaps = true;
            toast = {
              delivery = "terminal";
            };
          };

          experimental = {
            pane_history = false;
          };
        };
      };
    };
  };
}
