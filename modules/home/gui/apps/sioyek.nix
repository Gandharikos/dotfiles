{
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.gui.apps.sioyek;
in {
  options.my.gui.apps.sioyek = {
    enable =
      mkEnableOption "Sioyek"
      // {
        default = config.my.gui.enable;
      };
  };

  config = mkIf cfg.enable {
    programs.sioyek = with config.my.keyboard.keys; {
      enable = true;
      bindings = {
        # === Vim-style Navigation ===
        # Smooth scrolling
        move_up = k;
        move_down = j;
        move_left = h;
        move_right = l;

        # Page navigation
        screen_down = "<C-${j}>";
        screen_up = "<C-${k}>";
        next_page = J;
        previous_page = K;

        # Half-page scrolling
        move_down_visual = "<C-d>";
        move_up_visual = "<C-u>";

        # === Document Navigation ===
        goto_toc = "g${i}"; # gi for index/toc
        goto_beginning = "gg";
        goto_end = G;
        goto_page_with_page_number = "g${h}"; # gh for goto here

        # === Search ===
        search = "/";
        next_item = n;
        previous_item = N;
        command = ":";
        keys = "?";

        # === Bookmarks (Academic) ===
        add_bookmark = "m${h}"; # mh for mark here
        delete_bookmark = "d${h}"; # dh for delete here
        goto_bookmark = "'"; # ' like vim marks
        goto_bookmark_g = "g'"; # g' for global bookmarks

        # === Highlights (Academic) ===
        add_highlight = "z${h}"; # zh for zone highlight
        delete_highlight = "d${e}"; # de for delete highlight
        goto_next_highlight = "]${h}";
        goto_prev_highlight = "[${h}";

        # === Portals (Academic Linking) ===
        portal = p; # create portal/link
        edit_portal = P; # edit portal
        delete_portal = "d${p}"; # delete portal
        goto_portal = "g${p}"; # go to portal

        # === Smart Jump (References) ===
        open_link = "<Enter>"; # follow reference/link
        overview_definition = "<C-]>"; # like vim tag jump
        portal_to_overview = "<C-${o}>"; # like vim jumplist back

        # === Zoom ===
        zoom_in = "+";
        zoom_out = "-";
        fit_to_page_width = "z${w}";
        fit_to_page_height = "z${h}";

        # === Visual Mode (Text Selection) ===
        enter_visual_mark_mode = "v${h}"; # vh for visual highlight

        # === Rotation ===
        rotate_clockwise = ">";
        rotate_counterclockwise = "<";

        # === Presentation ===
        toggle_presentation_mode = "<C-${p}>";
        toggle_fullscreen = "<C-f>";

        # === Synctex (LaTeX Integration) ===
        synctex_under_cursor = "<C-LeftClick>";

        # === Copy/Yank ===
        copy = "y${y}"; # yy for yank

        # === Window Management ===
        quit = q;
        toggle_statusbar = s;
        toggle_one_window = "<C-${w}>";
        toggle_dark_mode = "c${i}"; # ci for color invert

        # === External Tools ===
        external_search = "g${s}"; # gs for google scholar search
        open_selected_url = "g${o}"; # go for goto url

        # === Misc ===
        reload = R;
        toggle_horizontal_scroll_lock = "z${l}"; # zl for zone lock
        prefs_user = "g${p}"; # gp for preferences
      };

      config = {
        # Font and display settings
        font_size = "14";
        ui_font = "JetBrains Mono Nerd Font";
        status_bar_font_size = "14";

        # Visual appearance
        linear_filter = "1";
        background_color = "1.0 1.0 1.0";
        text_highlight_color = "1.0 1.0 0.0";
        page_separator_color = "0.9 0.9 0.9";
        page_separator_width = "2";
        status_bar_color = "1 1 1";
        status_bar_text_color = "0 0 0";

        # Behavior
        should_launch_new_window = "1";
        show_doc_path = "1";
        single_click_selects_words = "1";

        # Academic features
        should_draw_highlight_outline = "1";
        should_highlight_links = "1";
        highlight_color_a = "1.0 1.0 0.0"; # Yellow for general highlights
        highlight_color_b = "0.0 1.0 0.0"; # Green for important
        highlight_color_c = "1.0 0.5 0.0"; # Orange for todo
        highlight_color_d = "1.0 0.0 0.0"; # Red for critical
        highlight_color_e = "0.5 0.5 1.0"; # Blue for reference

        # Portal settings (for academic linking)
        portal_color = "0.0 0.5 1.0";
        should_draw_portal_outline = "1";

        # Navigation
        startup_commands = ["toggle_horizontal_scroll_lock"];
        use_heuristic_if_text_not_found = "1";

        # Search
        should_highlight_searched_words = "1";

        # Performance
        prerender_next_page_count = "5";

        # Ruler and visual aids
        should_show_ruler = "0";

        # Window behavior
        fit_to_page_width = "1";
        default_dark_mode = "0";

        # Synctex support for LaTeX
        synctex_command = "nvim --headless -c \"VimtexInverseSearch %2 '%1'\"";

        # Custom colors for dark mode
        custom_background_color = "0.1 0.1 0.1";
        custom_text_color = "0.9 0.9 0.9";

        # Misc
        check_for_updates_on_startup = "0";
        should_use_multiple_monitors = "1";
        ruler_padding = "1.0";
        ruler_x_padding = "2.0";
      };
    };

    xdg.mimeApps.defaultApplicationPackages = [config.programs.sioyek.package];
  };
}
