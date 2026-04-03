{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.my.theme.colorscheme) palette;

  cfg = config.my.theme.tokyonight;
  enable = cfg.enable && config.my.gui.apps.sioyek.enable;
in
{
  config = mkIf enable {
    programs.sioyek.config = with palette; {
      background_color = bg;
      text_highlight_color = yellow;
      visual_mark_color = comment;

      search_highlight_color = yellow;
      link_highlight_color = blue;
      synctex_highlight_color = green;

      highlight_color_a = yellow;
      highlight_color_b = green;
      highlight_color_c = cyan;
      highlight_color_d = red;
      highlight_color_e = magenta;
      highlight_color_f = orange;
      highlight_color_g = blue;

      custom_background_color = bg;
      custom_text_color = fg;

      ui_text_color = fg;
      ui_background_color = bg_highlight;
      ui_selected_text_color = fg;
      ui_selected_background_color = bg_visual;

      status_bar_color = bg_highlight;
      status_bar_text_color = fg;

      portal_color = blue;
      page_separator_color = bg_highlight;

      default_dark_mode = if cfg.style == "day" then "0" else "1";
    };
  };
}
