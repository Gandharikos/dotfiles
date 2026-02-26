{
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.desktop.apps.zathura;
in {
  options.my.desktop.apps.zathura = {
    enable =
      mkEnableOption "Zathura"
      // {
        default = config.my.desktop.enable;
      };
  };

  config = mkIf cfg.enable {
    programs.zathura = {
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
        "[normal] n" = "scroll left";
        "[normal] o" = "scroll right";
        "[normal] e" = "scroll down";
        "[normal] i" = "scroll up";
        "[normal] <C-e>" = "bisect backward";
        "[normal] <C-i>" = "bisect forward";
        "[normal] <A-n>" = "scroll half-left";
        "[normal] <A-o>" = "scroll half-right";
        "[normal] <A-e>" = "scroll half-down";
        "[normal] <A-i>" = "scroll half-up";
        "[normal] j" = "jumplist forward";
        "[normal] J" = "jumplist backward";
        "[normal] E" = "navigate next";
        "[normal] I" = "navigate previous";
        "[normal] b" = "toggle_statusbar";
        "[normal] <Tab>" = "toggle_index";
        "[normal] h" = "focus_inputbar";
        "[normal] k" = "search forward";
        "[normal] K" = "search backward";
        "[normal] <C-->" = "zoom out";
        "[normal] <C-=>" = "zoom in";
        "[normal] <C-p>" = "toggle_presentation";
        "[normal] <C-f>" = "toggle_fullscreen";
        "[fullscreen] q" = "toggle_fullscreen";
        "[fullscreen] n" = "scroll";
        "[fullscreen] o" = "scroll";
        "[fullscreen] e" = "scroll";
        "[fullscreen] i" = "scroll";
        "[fullscreen] <C-e>" = "bisect";
        "[fullscreen] <C-i>" = "bisect";
        "[fullscreen] <A-n>" = "scroll";
        "[fullscreen] <A-o>" = "scroll";
        "[fullscreen] <A-e>" = "scroll";
        "[fullscreen] <A-i>" = "scroll";
        "[fullscreen] j" = "jumplist";
        "[fullscreen] J" = "jumplist";
        "[fullscreen] E" = "navigate";
        "[fullscreen] I" = "navigate";
        "[fullscreen] b" = "toggle_statusbar";
        "[fullscreen] <Tab>" = "toggle_index";
        "[fullscreen] h" = "focus_inputbar";
        "[fullscreen] k" = "search";
        "[fullscreen] K" = "search";
        "[fullscreen] <C-->" = "zoom";
        "[fullscreen] <C-=>" = "zoom";
        "[fullscreen] <C-p>" = "toggle_presentation";
        "[fullscreen] <C-f>" = "toggle_fullscreen";
        "[presentation] q" = "toggle_presentation";
        "[presentation] e" = "navigate";
        "[presentation] i" = "navigate";
        "[index] q" = "toggle_index";
        "[index] <Tab>" = "toggle_index";
        "[index] e" = "navigate_index";
        "[index] i" = "navigate_index";
        "[index] n" = "navigate_index";
        "[index] o" = "navigate_index";
        "[index] O" = "navigate_index";
        "[index] N" = "navigate_index";
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
