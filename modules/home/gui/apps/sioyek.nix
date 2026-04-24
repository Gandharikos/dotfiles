{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (lib.meta)
    getExe
    getExe'
    ;
  inherit (config.my) gui;
  cfg = config.my.gui.apps.sioyek;
  enable = gui.enable && cfg.enable;
  sioyekExe = getExe pkgs.sioyek;
  envExe = getExe' pkgs.coreutils "env";
  sioyekExec = "${envExe} QT_QPA_PLATFORM=xcb ${sioyekExe}";
  sioyekDesktop = pkgs.makeDesktopItem {
    name = "sioyek";
    desktopName = "Sioyek";
    comment = "PDF viewer for reading research papers and technical books";
    exec = "${sioyekExec} %f";
    icon = "sioyek-icon-linux";
    terminal = false;
    startupNotify = true;
    categories = [
      "Development"
      "Viewer"
    ];
    mimeTypes = [ "application/pdf" ];
    extraConfig = {
      Keywords = "pdf;viewer;reader;research;";
      StartupWMClass = "sioyek";
      TryExec = sioyekExe;
    };
  };
in
{
  options.my.gui.apps.sioyek = {
    enable = mkEnableOption "Sioyek" // {
      default = true;
    };
  };

  config = mkIf enable {
    home.shellAliases.sioyek = sioyekExec;

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
        page_separator_width = "2";

        # Behavior
        should_launch_new_window = "1";
        show_doc_path = "1";
        single_click_selects_words = "1";

        # Navigation
        startup_commands = [
          "toggle_horizontal_scroll_lock"
          "fit_to_page_width"
        ];

        # Synctex support for LaTeX
        inverse_search_command = "nvim --headless -c \"VimtexInverseSearch %2 '%1'\"";

        # Misc
        check_for_updates_on_startup = "0";
        should_use_multiple_monitors = "1";
        ruler_padding = "1.0";
        ruler_x_padding = "2.0";
      };
    };

    xdg.dataFile."applications/sioyek.desktop" = {
      source = "${sioyekDesktop}/share/applications/sioyek.desktop";
    };

    xdg.mimeApps.defaultApplicationPackages = [ pkgs.sioyek ];
  };
}
