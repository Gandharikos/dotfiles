{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.my.theme) tokyonight colorscheme;
  inherit (config.my.theme.general) transparent pad;
  inherit (colorscheme) palette;
  cfg = tokyonight;
in
{
  config = mkIf cfg.enable {
    programs.tmux.plugins = with pkgs.tmuxPlugins; [
      {
        plugin = mode-indicator;
        extraConfig =
          with palette;
          let
            status_bg = if transparent then "bg=default" else "bg=${bg_statusline}";
            pad_style = fg: "#[fg=${fg},${status_bg}]";
            gray_pad_style = pad_style "${bg_highlight}";
            blue_pad_style = pad_style "${blue}";
            left_pad = "${gray_pad_style}${pad.left}";
            right_pad = "${gray_pad_style}${pad.right}";
            current_left_pad = "${blue_pad_style}${pad.left}";
            current_right_pad = "${blue_pad_style}${pad.right}";
          in
          ''
            #################################### PLUGINS ###################################

            set -g @mode_indicator_prefix_prompt " WAIT"
            set -g @mode_indicator_prefix_mode_style fg=${orange},bg=${bg_highlight},bold
            set -g @mode_indicator_copy_prompt " COPY"
            set -g @mode_indicator_copy_mode_style fg=${green},bg=${bg_highlight},bold
            set -g @mode_indicator_sync_prompt " SYNC"
            set -g @mode_indicator_sync_mode_style fg=${magenta2},bg=${bg_highlight},bold
            set -g @mode_indicator_empty_prompt " TMUX"
            set -g @mode_indicator_empty_mode_style fg=${blue},bg=${bg_highlight},bold

            #################################### OPTIONS ###################################

            set -g status on
            set -g status-justify centre
            set -g status-position top
            set -g status-left-length 90
            set -g status-right-length 90
            set -g status-style ${status_bg}
            setw -g window-status-separator " "

            # set -g window-style ""
            # set -g window-active-style ""

            # Note: default window-status-activity-style is 'reverse'
            setw -g window-status-activity-style none
            setw -g window-status-bell-style none

            set -g message-style bg=${fg_gutter},fg=${blue}
            set -g message-command-style bg=${fg_gutter},fg=${blue}
            set-window-option -g mode-style bg=${bg_highlight},fg=${green}

            set -g pane-border-style fg=${fg_gutter}
            set -g pane-active-border-style fg=${blue}

            ##################################### FORMAT ###################################
            set -g status-left "${left_pad}#{tmux_mode_indicator}${right_pad} ${left_pad}#[fg=${info},bg=${bg_highlight}] #{=/-32/...:#{s|$USER|~|:#{b:pane_current_path}}}${right_pad}"
            set -g status-right "${left_pad}#[fg=${cyan},bg=${bg_highlight}] #S${right_pad} ${left_pad}#[fg=${fg},bg=${bg_highlight}] %H:%M${right_pad}"
            setw -g window-status-format "${left_pad}#{?window_activity_flag,#[fg=${orange}],#[fg=${fg}]}#[bg=${bg_highlight},italics]#I: #[noitalics]#W#{?window_last_flag,  ,}#{?window_activity_flag,  ,}#{?window_bell_flag, #[fg=${magenta2}]󰂞 ,}${right_pad}"
            setw -g window-status-current-format "${current_left_pad}#[fg=${bg},bg=${blue},italics]#I: #[bg=${blue},noitalics,bold]#{?window_zoomed_flag,[#W],#W}${current_right_pad}"
          '';
      }
    ];
  };
}
