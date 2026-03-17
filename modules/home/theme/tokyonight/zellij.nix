{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf mkForce;
  src = pkgs.vimPlugins.tokyonight-nvim;
  inherit (config.my.theme.colorscheme) slug;
  enable = cfg.enable && config.my.zellij.enable;
  inherit (config.my.theme) tokyonight colorscheme;
  inherit (colorscheme) palette;
  inherit (config.my.theme.general) transparent;
  cfg = tokyonight;
  zjstatusWasm = "${pkgs.my.zjstatus}/bin/zjstatus.wasm";
in
{
  config = mkIf enable {
    programs.zellij = {
      settings = {
        theme = slug;
        theme_dir = "${src}/extras/zellij";
        default_layout = mkForce "tmux";
      };
      layouts = {
        tmux = {
          layout = {
            _children = [
              {
                default_tab_template = {
                  _children = [
                    {
                      pane = {
                        size = 1;
                        borderless = true;
                        plugin = {
                          _props.location = "file:${zjstatusWasm}";
                          _children =
                            with palette;
                            let
                              statusline = if transparent then "default" else bg_statusline;
                            in
                            [
                              {
                                # source: https://github.com/merikan/.dotfiles/blob/main/config/zellij/themes/zjstatus/catppuccin.kdl

                                format_left = "#[bg=${statusline},fg=${bright_blue}]#[bg=${bright_blue},fg=${bg_dark},bold] {session} #[bg=${statusline}] {mode}#[bg=${statusline}] {tabs}";
                                format_center = "{notifications}";
                                format_right = "#[bg=${statusline},fg=${orange}]#[fg=${bg_dark},bg=${orange}] #[bg=${bg_highlight},fg=${orange},bold] {command_user}@{command_host}#[bg=${statusline},fg=${bg_highlight}] #[bg=${statusline},fg=${info}]#[bg=${info},fg=${bg_dark}]󰃭 #[bg=${bg_highlight},fg=${info},bold] {datetime}#[bg=${statusline},fg=${bg_highlight}]";
                                format_space = "#[bg=${statusline}]";
                                format_hide_on_overlength = "true";
                                format_precedence = "lrc";

                                border_enabled = "false";
                                border_char = "─";
                                border_format = "#[bg=${bg_highlight}]{char}";
                                border_position = "top";

                                hide_frame_for_single_pane = "false";

                                mode_normal = "#[bg=${green},fg=${bg_dark},bold] NORMAL#[bg=${statusline},fg=${green}]";
                                mode_tmux = "#[bg=${blue},fg=${bg_dark},bold] TMUX#[bg=${statusline},fg=${blue}]";
                                mode_locked = "#[bg=${red},fg=${bg_dark},bold] LOCKED#[bg=${statusline},fg=${red}]";
                                mode_pane = "#[bg=${green2},fg=${bg_dark},bold] PANE#[bg=${statusline},fg=${green2}]";
                                mode_tab = "#[bg=${teal},fg=${bg_dark},bold] TAB#[bg=${statusline},fg=${teal}]";
                                mode_scroll = "#[bg=${orange},fg=${bg_dark},bold] SCROLL#[bg=${bg_highlight},fg=${orange}]";
                                mode_enter_search = "#[bg=${orange},fg=${bg_dark},bold] ENT-SEARCH#[bg=${statusline},fg=${orange}]";
                                mode_search = "#[bg=${orange},fg=${bg_dark},bold] SEARCHARCH#[bg=${statusline},fg=${orange}]";
                                mode_resize = "#[bg=${yellow},fg=${bg_dark},bold] RESIZE#[bg=${bg_highlight},fg=${yellow}]";
                                mode_rename_tab = "#[bg=${yellow},fg=${bg_dark},bold] RENAME-TAB#[bg=${statusline},fg=${yellow}]";
                                mode_rename_pane = "#[bg=${yellow},fg=${bg_dark},bold] RENAME-PANE#[bg=${statusline},fg=${yellow}]";
                                mode_move = "#[bg=${yellow},fg=${bg_dark},bold] MOVE#[bg=${statusline},fg=${yellow}]";
                                mode_session = "#[bg=${magenta2},fg=${bg_dark},bold] SESSION#[bg=${statusline},fg=${magenta2}]";
                                mode_prompt = "#[bg=${magenta2},fg=${bg_dark},bold] PROMPT#[bg=${statusline},fg=${magenta2}]";

                                tab_normal = "#[fg=${blue}]#[bg=${blue},fg=${bg_dark},bold]{index} #[bg=${bg_highlight},fg=${blue},bold] {name}{floating_indicator}#[fg=${bg_highlight}]";
                                tab_normal_fullscreen = "#[fg=${blue}]#[bg=${blue},fg=${bg_dark},bold]{index} #[bg=${bg_highlight},fg=${blue},bold] {name}{fullscreen_indicator}#[fg=${bg_highlight}]";
                                tab_normal_sync = "#[fg=${blue}]#[bg=${blue},fg=${bg_dark},bold]{index} #[bg=${bg_highlight},fg=${blue},bold] {name}{sync_indicator}#[fg=${bg_highlight}]";
                                tab_active = "#[fg=${purple}]#[bg=${purple},fg=${bg_dark},bold]{index} #[bg=${bg_highlight},fg=${purple},bold] {name}{floating_indicator}#[fg=${bg_highlight}]";
                                tab_active_fullscreen = "#[fg=${purple}]#[bg=${purple},fg=${bg_dark},bold]{index} #[bg=${bg_highlight},fg=${purple},bold] {name}{fullscreen_indicator}#[fg=${bg_highlight}]";
                                tab_active_sync = "#[fg=${purple}]#[bg=${purple},fg=${bg_dark},bold]{index} #[bg=${bg_highlight},fg=${purple},bold] {name}{sync_indicator}#[fg=${bg_highlight}]";
                                tab_separator = " ";

                                tab_sync_indicator = " ";
                                tab_fullscreen_indicator = " 󰊓";
                                tab_floating_indicator = " 󰹙";

                                notification_format_unread = "#[bg={bg_highlight},fg=${yellow}]#[bg=${yellow},fg=${bg_dark}] #[bg=${bg_highlight},fg=${yellow}] {message}#[fg=${yellow}]";
                                notification_format_no_notifications = "";
                                notification_show_interval = "10";

                                command_host_command = "uname -n";
                                command_host_format = "{stdout}";
                                command_host_interval = "0";
                                command_host_rendermode = "static";

                                command_user_command = "whoami";
                                command_user_format = "{stdout}";
                                command_user_interval = "10";
                                command_user_rendermode = "static";

                                datetime = "{format}";
                                datetime_format = "%Y-%m-%d 󰅐 %I:%M %p";
                                datetime_timezone = "Asia/Kolkata";
                              }
                            ];
                        };
                      };
                    }
                    {
                      children = { };
                    }
                  ];
                };
              }
            ];
          };
        };
      };
    };
  };
}
