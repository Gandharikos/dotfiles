{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkAfter mkDefault mkIf;
  cfg = config.nixporn.colorschemes.catppuccin;
  tmux = config.my.tmux;
  enable = config.nixporn.colorscheme == "catppuccin" && config.my.tmux.enable;
  plugin = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "catppuccin";
    version = "unstable";
    src = pkgs.nixporn.catppuccin.tmux;
  };
in
{
  config = mkIf enable {
    nixporn.tmux.enable = mkDefault false;

    programs.tmux.plugins = [
      {
        inherit plugin;
        extraConfig = ''
          set -gu @catppuccin_status_background
          set -gu @catppuccin_status_connect_separator
          set -gu @catppuccin_status_module_bg_color
          set -gu @catppuccin_status_right_separator
          set -gu @catppuccin_status_fill
          set -gu @catppuccin_window_flags
          set -gu @catppuccin_window_left_separator
          set -gu @catppuccin_window_middle_separator
          set -gu @catppuccin_window_right_separator
          set -gu @catppuccin_window_current_left_separator
          set -gu @catppuccin_window_current_middle_separator
          set -gu @catppuccin_window_current_right_separator
          set -g @catppuccin_flavor "${cfg.flavor}"
          set -g @catppuccin_window_status_style "rounded"
          set -g @catppuccin_pane_status_enabled "yes"
        '';
      }
    ];

    programs.tmux.extraConfig = mkAfter ''
      set -g status-position ${tmux.statusPosition}
      set -g status-right-length 100
      set -g status-left-length 100
      set -g status-left ""
      set -g status-right "#{E:@catppuccin_status_application}"
      set -ag status-right "#{E:@catppuccin_status_session}"
      set -ag status-right "#{E:@catppuccin_status_date_time}"
      set -g status-style default
      setw -gF window-status-format "#[fg=#{E:@catppuccin_window_number_color},bg=default]#[fg=#{@thm_crust},bg=#{E:@catppuccin_window_number_color}]#{@catppuccin_window_number} #[fg=#{@thm_fg},bg=#{E:@catppuccin_window_text_color}]#{@catppuccin_window_text}#[fg=#{E:@catppuccin_window_text_color},bg=default]"
      setw -gF window-status-current-format "#[fg=#{E:@catppuccin_window_current_number_color},bg=default]#[fg=#{@thm_crust},bg=#{E:@catppuccin_window_current_number_color}]#{@catppuccin_window_current_number} #[fg=#{@thm_fg},bg=#{E:@catppuccin_window_current_text_color}]#{@catppuccin_window_current_text}#[fg=#{E:@catppuccin_window_current_text_color},bg=default]"
    '';
  };
}
