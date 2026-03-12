{pkgs, ...}: {
  programs.tmux.plugins = with pkgs.tmuxPlugins; [
    # theme
    # {
    #   plugin = catppuccin;
    #   extraConfig = ''
    #     set -g @catppuccin_pill_theme_enabled on
    #     set -g @catppuccin_window_tabs_enabled on
    #     set -g @catppuccin_date_time "%H:%M"
    #   '';
    # }
    {
      plugin = resurrect;
      extraConfig = ''
        set -g @resurrect-capture-pane-contents 'on'
        set -g @resurrect-strategy-nvim 'session'
      '';
    }
    {
      plugin = continuum;
      extraConfig = ''
        set -g @continuum-boot 'off'
        set -g @continuum-restore 'on'
        # Save frequently so reboots do not race the default 15m interval.
        set -g @continuum-save-interval '1'
      '';
    }
    {
      plugin = jump;
      extraConfig = "set -g @jump-key 'Enter'";
    }
    yank
    # {
    #   plugin = open;
    #   extraConfig = ''
    #     set -g @open 'x'
    #     set -g @open-editor 'X'
    #   '';
    # }
    {
      plugin = tmux-fzf;
      extraConfig = ''
        TMUX_FZF_LAUNCH_KEY="/"
        TMUX_FZF_ORDER="session|window|pane|command|keybinding|clipboard|process"
      '';
    }
    # {
    #   plugin = smart-splits;
    #   extraConfig = with config.my.keyboard.keys; ''
    #     set -g @smart-splits_no_wrap \'\'
    #     set -g @smart-splits_move_left_key  'C-${h}' # key-mapping for navigation.
    #     set -g @smart-splits_move_down_key  'C-${j}' #  --"--
    #     set -g @smart-splits_move_up_key    'C-${k}' #  --"--
    #     set -g @smart-splits_move_right_key 'C-${l}' #  --"--
    #     set -g @smart-splits_resize_left_key  'A-${h}' # key-mapping for resizing.
    #     set -g @smart-splits_resize_down_key  'A-${j}' #  --"--
    #     set -g @smart-splits_resize_right_key 'A-${k}' #  --"--
    #     set -g @smart-splits_resize_up_key    'A-${l}' #  --"--
    #     set -g @smart-splits_resize_step_size '3' # change the step-size for resizing.
    #   '';
    # }
  ];
}
