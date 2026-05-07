{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  inherit (lib.strings) optionalString;
  isColemak = config.dot.keyboard.layout == "colemak";

  clipboardCmd = if isDarwin then "pbcopy" else "${pkgs.wl-clipboard}/bin/wl-copy";
in
{
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
        set -g @resurrect-strategy-vim 'session'
        set -g @resurrect-strategy-nvim 'session'
        set -g @resurrect-processes 'vi vim nvim nvim-ruby cat less more tail watch'
        set -g @resurrect-dir ~/.local/share/tmux/resurrect
        # Borrowed from: https://github.com/tmux-plugins/tmux-resurrect/issues/247#issuecomment-2387643976
        set -g @resurrect-hook-post-save-all "sed -i 's| --cmd .*-vim-pack-dir||g; s|/etc/profiles/per-user/$USER/bin/||g; s|/nix/store/.*/bin/||g' $(readlink -f ~/.local/share/tmux/resurrect)"
      '';
    }
    {
      plugin = continuum;
      extraConfig = ''
        set -g @continuum-boot 'off'
        set -g @continuum-restore 'on'
        set -g @continuum-save-interval '10'
      '';
    }
    {
      plugin = tmux-thumbs;
      extraConfig = ''
        # plugin setup
        set -g @thumbs-key 'Enter'
        ${optionalString isColemak "set -g @thumbs-alphabet colemak-homerow"}
        set -g @thumbs-command 'echo -n {} | ${clipboardCmd} && tmux display-message "Copied to clipboard: {}"'
      '';
    }
    {
      plugin = tmux-which-key;
      extraConfig = ''
        set -g @tmux-which-key-xdg-enable 1;
        set -g @tmux-which-key-disable-autobuild 1
      '';
    }
    yank
    {
      plugin = tmux-fzf;
      extraConfig = ''
        TMUX_FZF_LAUNCH_KEY="/"
        TMUX_FZF_ORDER="session|window|pane|command|keybinding|clipboard|process"
      '';
    }
    # {
    #   plugin = smart-splits;
    #   extraConfig = with config.dot.keyboard.keys; ''
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
