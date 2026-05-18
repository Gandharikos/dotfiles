{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.my.gui.apps.zathura;
  enable = osConfig.dot.gui.enable && cfg.enable;
in
{
  options.my.gui.apps.zathura = {
    enable = mkEnableOption "Zathura" // {
      default = isLinux;
    };
  };

  config = mkIf enable {
    programs.zathura = with osConfig.dot.keyboard.keys; {
      enable = true;
      options = {
        # when selection text with mouse, copy to clipboard
        selection-clipboard = "clipboard";

        # keep several lines of text when scrolling a screenful
        scroll-full-overlap = "0.2";

        scroll-page-aware = true;
        window-title-basename = true;
        adjust-open = "width";
        statusbar-home-title = true;
        vertical-center = true;
        synctex = true;

        font = "JetBrains Mono Nerd font Bold 12";
        zoom-step = 3;
      };
      mappings = {
        # Navigation (hjkl style)
        "[normal] ${h}" = "scroll left";
        "[normal] ${l}" = "scroll right";
        "[normal] ${j}" = "scroll down";
        "[normal] ${k}" = "scroll up";
        "[normal] <C-${j}>" = "bisect backward";
        "[normal] <C-${k}>" = "bisect forward";
        "[normal] <A-${h}>" = "scroll half-left";
        "[normal] <A-${l}>" = "scroll half-right";
        "[normal] <A-${j}>" = "scroll half-down";
        "[normal] <A-${k}>" = "scroll half-up";

        # Jumplist (e for forward, E for backward in QWERTY)
        "[normal] ${e}" = "jumplist forward";
        "[normal] ${E}" = "jumplist backward";

        # Navigate pages (i/I for next/prev in QWERTY)
        "[normal] ${J}" = "navigate next";
        "[normal] ${K}" = "navigate previous";

        # Other commands
        "[normal] b" = "toggle_statusbar";
        "[normal] <Tab>" = "toggle_index";
        "[normal] ${i}" = "focus_inputbar";
        "[normal] ${n}" = "search forward";
        "[normal] ${N}" = "search backward";
        "[normal] <C-->" = "zoom out";
        "[normal] <C-=>" = "zoom in";
        "[normal] <C-p>" = "toggle_presentation";
        "[normal] <C-f>" = "toggle_fullscreen";

        # Fullscreen mode
        "[fullscreen] q" = "toggle_fullscreen";
        "[fullscreen] ${h}" = "scroll";
        "[fullscreen] ${l}" = "scroll";
        "[fullscreen] ${j}" = "scroll";
        "[fullscreen] ${k}" = "scroll";
        "[fullscreen] <C-${j}>" = "bisect";
        "[fullscreen] <C-${k}>" = "bisect";
        "[fullscreen] <A-${h}>" = "scroll";
        "[fullscreen] <A-${l}>" = "scroll";
        "[fullscreen] <A-${j}>" = "scroll";
        "[fullscreen] <A-${k}>" = "scroll";
        "[fullscreen] ${e}" = "jumplist";
        "[fullscreen] ${E}" = "jumplist";
        "[fullscreen] ${J}" = "navigate";
        "[fullscreen] ${K}" = "navigate";
        "[fullscreen] b" = "toggle_statusbar";
        "[fullscreen] <Tab>" = "toggle_index";
        "[fullscreen] ${i}" = "focus_inputbar";
        "[fullscreen] ${n}" = "search";
        "[fullscreen] ${N}" = "search";
        "[fullscreen] <C-->" = "zoom";
        "[fullscreen] <C-=>" = "zoom";
        "[fullscreen] <C-p>" = "toggle_presentation";
        "[fullscreen] <C-f>" = "toggle_fullscreen";

        # Presentation mode
        "[presentation] q" = "toggle_presentation";
        "[presentation] ${j}" = "navigate";
        "[presentation] ${k}" = "navigate";

        # Index mode
        "[index] q" = "toggle_index";
        "[index] <Tab>" = "toggle_index";
        "[index] ${j}" = "navigate_index";
        "[index] ${k}" = "navigate_index";
        "[index] ${h}" = "navigate_index";
        "[index] ${l}" = "navigate_index";
        "[index] ${L}" = "navigate_index";
        "[index] ${H}" = "navigate_index";
        "[index] <Space>" = "navigate_index";
        "[index] <Return>" = "navigate_index";
      };
      # extraConfig = "include catppuccin-mocha";
    };

    # xdg.configFile = {
    #   "zathura/catppuccin-latte".source = pkgs.fetchurl {
    #     url = "https://raw.githubusercontent.com/catppuccin/zathura/main/src/catppuccin-latte";
    #     hash = "sha256-h1USn+8HvCJuVlpeVQyzSniv56R/QgWyhhRjNm9bCfY=";
    #   };
    #   "zathura/catppuccin-mocha".source = pkgs.fetchurl {
    #     url = "https://raw.githubusercontent.com/catppuccin/zathura/main/src/catppuccin-mocha";
    #     hash = "sha256-POxMpm77Pd0qywy/jYzZBXF/uAKHSQ0hwtXD4wl8S2Q=";
    #   };
    # };
  };
}
