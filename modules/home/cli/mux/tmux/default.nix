{
  pkgs,
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
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf mkBefore;
  inherit (lib.meta) getExe;
  shell = getExe (builtins.getAttr config.my.shell pkgs);
in
{
  imports = lib.dot.scanPaths ./.;

  options.my.tmux = {
    enable = mkEnableOption "tmux" // {
      default = config.my.mux.default == "tmux";
    };
  };

  config = mkIf cfg.enable {
    programs = {
      fish = mkIf autoStart {
        # TODO: use tmux.fish instaed
        interactiveShellInit = ''
          if not set -q TMUX
             and test -z "$SSH_TTY"
             and test -z "$WSL_DISTRO_NAME"
             and test -z "$INSIDE_EMACS"
             and test -z "$EMACS"
             and test -z "$VIM"
             and test -z "$NVIM"
             and test -z "$INSIDE_PYCHARM"
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
              && [[ -z "$WSL_DISTRO_NAME" ]] \
              && [[ -z "$INSIDE_PYCHARM" ]] \
              && [[ -z "$EMACS" ]] \
              && [[ -z "$VIM" ]] \
              && [[ -z "$NVIM" ]] \
              && [[ -z "$INSIDE_EMACS" ]] \
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
