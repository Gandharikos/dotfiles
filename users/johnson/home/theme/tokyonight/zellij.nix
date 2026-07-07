{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkDefault mkIf mkMerge;
  inherit (config.nixporn.colorschemes.tokyonight) slug;
  colorschemeEnable = config.nixporn.colorscheme == "tokyonight";
  enable = colorschemeEnable && config.my.zellij.enable;
  inherit (config.nixporn) palette;
  transparent = config.nixporn.transparent;
  pad = {
    left = "";
    right = "";
  };
  zjstatusWasm = "${lib.getExe' pkgs.dot.zjstatus "zjstatus.wasm"}";
in
{
  config = mkMerge [
    (mkIf colorschemeEnable {
      nixporn.zellij.enable = mkDefault false;
    })
    (mkIf enable {
      my.zellij.template = {
        default_tab_template = {
          _children = [
            {
              pane = {
                size = 1;
                borderless = true;
                plugin =
                  with palette;
                  let
                    statusline = if transparent then "default" else bg_statusline;
                    l_pad = "#[bg=${statusline},fg=${bg_highlight}]${pad.left}";
                    r_pad = "#[bg=${statusline},fg=${bg_highlight}]${pad.right}";
                  in
                  {
                    _props.location = "file:${zjstatusWasm}";

                    # source: https://github.com/merikan/.dotfiles/blob/main/config/zellij/themes/zjstatus/catppuccin.kdl
                    format_left = "{mode} ${l_pad}#[bg=${bg_highlight},fg=${cyan}] {session}${r_pad} {notifications}";
                    format_center = "{tabs}";
                    format_right = "${l_pad}#[bg=${bg_highlight},fg=${orange}] {command_user}@{command_host}${r_pad} ${l_pad}#[bg=${bg_highlight},fg=${info}]󰃭 {datetime}${r_pad}";
                    format_space = "#[bg=${statusline}]";
                    format_hide_on_overlength = "true";
                    format_precedence = "lrc";

                    border_enabled = "false";
                    border_char = "─";
                    border_format = "#[bg=${bg_highlight}]{char}";
                    border_position = "top";

                    hide_frame_for_single_pane = "false";

                    mode_normal = "${l_pad}#[bg=${bg_highlight},fg=${blue},bold] NORMAL${r_pad}";
                    mode_tmux = "${l_pad}#[bg=${bg_highlight},fg=${green},bold] TMUX${r_pad}";
                    mode_locked = "${l_pad}#[bg=${bg_highlight},fg=${red},bold] LOCKED${r_pad}";
                    mode_pane = "${l_pad}#[bg=${bg_highlight},fg=${green2},bold] PANE${r_pad}";
                    mode_tab = "${l_pad}#[bg=${bg_highlight},fg=${teal},bold] TAB${r_pad}";
                    mode_scroll = "${l_pad}#[bg=${bg_highlight},fg=${orange},bold] SCROLL${r_pad}";
                    mode_enter_search = "${l_pad}#[bg=${bg_highlight},fg=${orange},bold] ENT-SEARCH${r_pad}";
                    mode_search = "${l_pad}#[bg=${bg_highlight},fg=${orange},bold] SEARCH${r_pad}";
                    mode_resize = "${l_pad}#[bg=${bg_highlight},fg=${yellow},bold] RESIZE${r_pad}";
                    mode_rename_tab = "${l_pad}#[bg=${bg_highlight},fg=${yellow},bold] RENAME-TAB${r_pad}";
                    mode_rename_pane = "${l_pad}#[bg=${bg_highlight},fg=${yellow},bold] RENAME-PANE${r_pad}";
                    mode_move = "${l_pad}#[bg=${bg_highlight},fg=${yellow},bold] MOVE${r_pad}";
                    mode_session = "${l_pad}#[bg=${bg_highlight},fg=${magenta2},bold] SESSION${r_pad}";
                    mode_prompt = "${l_pad}#[bg=${bg_highlight},fg=${magenta2},bold] PROMPT${r_pad}";

                    tab_normal = "${l_pad}#[bg=${bg_highlight},fg=${fg},bold]{index}: {name}{floating_indicator}${r_pad}";
                    tab_normal_fullscreen = "${l_pad}#[bg=${bg_highlight},fg=${fg},bold]{index}: {name}{fullscreen_indicator}${r_pad}";
                    tab_normal_sync = "${l_pad}#[bg=${bg_highlight},fg=${fg},bold]{index}: {name}{sync_indicator}${r_pad}";
                    tab_active = "#[bg=${statusline},fg=${blue}]${pad.left}#[bg=${blue},fg=${bg},bold]{index}: {name}{floating_indicator}#[bg=${statusline},fg=${blue}]${pad.right}";
                    tab_active_fullscreen = "#[bg=${statusline},fg=${blue}]${pad.left}#[bg=${blue},fg=${bg},bold]{index}: {name}{fullscreen_indicator}#[bg=${statusline},fg=${blue}]${pad.right}";
                    tab_active_sync = "#[bg=${statusline},fg=${blue}]${pad.left}#[bg=${blue},fg=${bg},bold]{index}: {name}{sync_indicator}#[bg=${statusline},fg=${blue}]${pad.right}";
                    tab_separator = " ";

                    tab_sync_indicator = " ";
                    tab_fullscreen_indicator = " 󰊓";
                    tab_floating_indicator = " 󰹙";

                    notification_format_unread = "${l_pad}#[bg=${bg_highlight},fg=${yellow}] {message}${r_pad}";
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
                    datetime_format = "%Y-%m-%d 󰅐 %H:%M";
                    datetime_timezone = "Asia/Kolkata";
                  };
              };
            }
            {
              children = { };
            }
          ];
        };
      };

      programs.zellij = {
        settings = {
          theme = slug;
          theme_dir = "${config.xdg.configHome}/zellij/themes";
        };
        themes.${slug} = with palette; {
          themes.${slug} = {
            inherit
              fg
              red
              green
              yellow
              blue
              magenta
              cyan
              orange
              ;
            white = palette.ansi.white;
            bg = bg_highlight;
            black = bg;

            frame_selected = {
              base = blue;
              background = bg;
              emphasis_0 = orange;
              emphasis_1 = blue;
              emphasis_2 = magenta;
              emphasis_3 = fg;
            };

            frame_unselected = {
              base = comment;
              background = bg;
              emphasis_0 = comment;
              emphasis_1 = fg_dark;
              emphasis_2 = dark3;
              emphasis_3 = fg_dark;
            };

            frame_highlight = {
              base = orange;
              background = bg;
              emphasis_0 = yellow;
              emphasis_1 = orange;
              emphasis_2 = magenta;
              emphasis_3 = fg;
            };
          };
        };
      };
    })
  ];
}
