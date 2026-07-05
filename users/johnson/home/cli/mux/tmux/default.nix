{
  lib,
  config,
  ...
}:
let
  shellAliases = {
    "t" = "tmux";
  };
  cfg = config.my.tmux;
  autoStart = config.my.mux.autoStart && config.my.mux.default == "tmux";
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) enum;
  inherit (lib.modules) mkIf mkBefore;
  shell = "${config.home.profileDirectory}/bin/${config.my.shell}";
in
{
  imports = lib.dot.scanPaths ./.;

  options.my.tmux = {
    enable = mkEnableOption "tmux" // {
      default = config.my.mux.default == "tmux";
    };
    statusPosition = mkOption {
      type = enum [
        "top"
        "bottom"
      ];
      default = "top";
      description = "Position of the tmux status bar.";
    };
  };

  config = mkIf cfg.enable {
    programs = {
      fish = mkIf autoStart {
        # TODO: use tmux.fish instaed
        interactiveShellInit = ''
          if not set -q TMUX
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
             and test -z "$ZELLIJ_SESSION_NAME"
             and test "$TERM_PROGRAM" != "vscode"
            tmux attach-session; or tmux
          end
        '';
      };
      zsh =
        let
          # see: https://github.com/catppuccin/nix/pull/543/files
          key =
            if builtins.hasAttr "initContent" config.programs.zsh then "initContent" else "initExtraFirst";
        in
        mkIf autoStart {
          "${key}" = mkBefore ''
            if [[ -z "$TMUX" ]] \
              && [[ -z "$SSH_TTY" ]] \
              && [[ -z "$SSH_CONNECTION" ]] \
              && [[ -z "$SSH_CLIENT" ]] \
              && [[ -z "$WSL_DISTRO_NAME" ]] \
              && [[ -z "$INSIDE_PYCHARM" ]] \
              && [[ -z "$EMACS" ]] \
              && [[ -z "$VIM" ]] \
              && [[ -z "$NVIM" ]] \
              && [[ -z "$INSIDE_EMACS" ]] \
              && [[ -z "$ZED_TERMINAL" ]] \
              && [[ -z "$ZELLIJ_SESSION_NAME" ]] \
              && [[ "$TERM_PROGRAM" != "vscode" ]]
            then
              tmux attach-session || tmux;
            fi
          '';
        };
      tmux = {
        enable = true;
        baseIndex = 1;
        clock24 = true;
        mouse = true;
        prefix = "C-a";
        keyMode = "vi";
        escapeTime = 0;
        historyLimit = 50000;
        focusEvents = true;
        aggressiveResize = true;
        terminal = "screen-256color";
        inherit shell;
      };
    };

    home = {
      inherit shellAliases;
    };
  };
}
