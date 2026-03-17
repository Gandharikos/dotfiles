{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  palette = rec {
    cursor = {
      baseColor = magenta2;
      outlineColor = bg_highlight;
      watchBackgroundColor = orange;
    };
    bg = "#222436";
    bg_dark = "#1e2030";
    bg_dark1 = "#191B29";
    bg_float = "#1e2030";
    bg_highlight = "#2f334d";
    bg_popup = "#1e2030";
    bg_search = "#3e68d7";
    bg_sidebar = "#1e2030";
    bg_statusline = "#1e2030";
    bg_visual = "#2d3f76";
    black = "#1b1d2b";
    blue = "#82aaff";
    blue0 = "#3e68d7";
    blue1 = "#65bcff";
    blue2 = "#0db9d7";
    blue5 = "#89ddff";
    blue6 = "#b4f9f8";
    blue7 = "#394b70";
    border = "#1b1d2b";
    border_highlight = "#589ed7";
    comment = "#636da6";
    cyan = "#86e1fc";
    dark3 = "#545c7e";
    dark5 = "#737aa2";
    error = "#c53b53";
    fg = "#c8d3f5";
    fg_dark = "#828bb8";
    fg_float = "#c8d3f5";
    fg_gutter = "#3b4261";
    fg_sidebar = "#828bb8";
    green = "#c3e88d";
    green1 = "#4fd6be";
    green2 = "#41a6b5";
    hint = "#4fd6be";
    info = "#0db9d7";
    magenta = "#c099ff";
    magenta2 = "#ff007c";
    orange = "#ff966c";
    purple = "#fca7ea";
    red = "#ff757f";
    red1 = "#c53b53";
    teal = "#4fd6be";
    bright_black = "#444a73";
    bright_blue = "#9ab8ff";
    bright_cyan = "#b2ebff";
    bright_green = "#c7fb6d";
    bright_magenta = "#caabff";
    bright_red = "#ff8d94";
    white = "#828bb8";
    bright_white = "#c8d3f5";
    bright_yellow = "#ffd8ab";
    terminal_black = "#444a73";
    todo = "#82aaff";
    warning = "#ffc777";
    yellow = "#ffc777";
  };
  cfg = config.my.theme.tokyonight;
  enable = cfg.enable && cfg.style == "moon";
in
{
  config = mkIf enable {
    # my.theme.wallpaper = pkgs.fetchurl {
    #   url = "https://github.com/huwqchn/wallpapers/blob/main/tokyonight/Night_City_Street_Umbrella.jpg";
    #   sha256 = "19nmdw8jldkh5niav478qwzvsnvfr3id3a02r4lgvmmb94kqv9xw";
    # };
    my.theme = {
      wallpaper = ./walls/tokyo-photo1.jpg;
      # I hated base16 scheme; so I made my own
      colorscheme = {
        inherit palette;
      };
    };
  };
}
