{
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.my) terminal;
  cfg = config.my.desktop.apps.kitty;
in {
  options.my.desktop.apps.kitty = {
    enable =
      mkEnableOption "kitty"
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable {
    programs.kitty = with config.my.keyboard.keys; {
      enable = true;
      font = {
        name = terminal.font;
        inherit (terminal) size;
      };
      settings = {
        symbol_map = "U+23FB-U+23FE,U+2665,U+26A1,U+2B58,U+E000-U+E00A,U+E0A0-U+E0A3,U+E0B0-U+E0C8,U+E0CA,U+E0CC-U+E0D2,U+E0D4,U+E200-U+E2A9,U+E300-U+E3E3,U+E5FA-U+E634,U+E700-U+E7C5,U+EA60-U+EBEB,U+F000-U+F2E0,U+F300-U+F32F,U+F400-U+F4A9,U+F500-U+F8FF Symbols Nerd Font Mono";
        disable_ligatures = "cursor";
        scrollback_lines = 10000;
        touch_scroll_multiplier = 1;
        wheel_scroll_multiplier = 5;
        copy_on_select = "yes";
        enable_audio_bell = "no";
        remember_window_size = "yes";
        window_padding_width = terminal.padding;
        background_opacity = terminal.opacity;
        background_blur = 64;
        enabled_layouts = "Splits,Stack";
        hide_window_decorations = "yes";
        tab_bar_style = "powerline";
        tab_separator = " ";
        dynamic_background_opacity = "yes";
        tab_title_template = "{title}{fmt.bold}{'  ' if num_windows > 1 and layout_name == 'stack' else ''}";
        cursor = "none";
      };
      keybindings = {
        "ctrl+shift+c" = "copy_to_clipboard";
        "ctrl+shift+v" = "paste_from_clipboard";
        "ctrl+shift+s" = "paste_from_selection";
        "ctrl+shift+p" = "pass_selection_to_program";
        "ctrl+shift+u" = "scroll_line_up";
        "ctrl+shift+d" = "scroll_line_down";
        "ctrl+shift+page_up" = "scroll_page_up";
        "ctrl+shift+page_down" = "scroll_page_downt";
        "ctrl+shift+home" = "scroll_home";
        "ctrl+shift+end" = "scroll_end";
        "ctrl+shift+t" = "new_tab";
        "ctrl+shift+enter" = "launch --location=split --cwd=current";
        "ctrl+shift+w" = "close_window";
        "ctrl+shift+r" = "show_scrollback";
        "ctrl+shift+f" = "move_window_forward";
        "ctrl+shift+b" = "move_window_backward";
        "ctrl+shift+[" = "next_tab";
        "ctrl+shift+]" = "previous_tab";
        "ctrl+shift+q" = "close_tab";
        "ctrl+shift+." = "move_tab_forward";
        "ctrl+shift+," = "move_tab_backward";
        "ctrl+shift+l" = "next_layout";
        "ctrl+shift+equal" = "change_font_size all +2.0";
        "ctrl+shift+plus" = "change_font_size all +2.0";
        "ctrl+shift+minus" = "change_font_size all -2.0";
        "ctrl+shift+kp_subtract" = "change_font_size all -2.0";
        "ctrl+shift+backspace" = "change_font_size all 0";
        "ctrl+shift+h" = "open_url_with_hints";
        "ctrl+shift+z" = "toggle_fullscreen";
        "ctrl+shift+m" = "toggle_layout stack";
        # Ctrl + H remap
        "ctrl+h" = "send_text all x1b[104;5u";
        # Ctrl + I remap
        "ctrl+i" = "send_text all x1b[105;5u";
        # Ctrl + M remap
        "ctrl+m" = "send_text all x1b[109;5u";
        # Ctrl 0 - 9
        "ctrl+0" = "send_text all x1b[48;5u";
        "ctrl+1" = "send_text all x1b[49;5u";
        "ctrl+2" = "send_text all x1b[50;5u";
        "ctrl+3" = "send_text all x1b[51;5u";
        "ctrl+4" = "send_text all x1b[52;5u";
        "ctrl+5" = "send_text all x1b[53;5u";
        "ctrl+6" = "send_text all x1b[54;5u";
        "ctrl+7" = "send_text all x1b[55;5u";
        "ctrl+8" = "send_text all x1b[56;5u";
        "ctrl+9" = "send_text all x1b[57;5u";
        # Ctrl + . , ;
        "ctrl+." = "send_text all x1b[46;5u";
        "ctrl+," = "send_text all x1b[44;5u";
        "ctrl+;" = "send_text all x1b[59;5u";
        # "ctrl+shift+." = "send_text all \x1b[46;6u";
        # "ctrl+shift+," = "send_text all \x1b[44;6u";
        # "ctrl+shift+;" = "send_text all \x1b[59;6u";
        # Shift + Enter
        "shift+enter" = "send_text all x1b[13;2u";
      };
      extraConfig = ''
        map ctrl+${h} neighboring_window left
        map ctrl+${j} neighboring_window down
        map ctrl+${k} neighboring_window up
        map ctrl+${l} neighboring_window right

        # Unset the mapping to pass the keys to neovim
        map --when-focus-on var:IS_NVIM ctrl+${h}
        map --when-focus-on var:IS_NVIM ctrl+${j}
        map --when-focus-on var:IS_NVIM ctrl+${k}
        map --when-focus-on var:IS_NVIM ctrl+${l}

        # the 3 here is the resize amount, adjust as needed
        map alt+down kitten relative_resize.py down  3
        map alt+up kitten relative_resize.py up    3
        map alt+left kitten relative_resize.py left  3
        map alt+right kitten relative_resize.py right 3

        map --when-focus-on var:IS_NVIM alt+down
        map --when-focus-on var:IS_NVIM alt+up
        map --when-focus-on var:IS_NVIM alt+left
        map --when-focus-on var:IS_NVIM alt+right

        # smart quit
        map ctrl+q close_window
        map --when-focus-on var:IS_NVIM ctrl+q
      '';
      # macOS specific settings
      darwinLaunchOptions = ["--start-as=maximized"];
    };
  };
}
