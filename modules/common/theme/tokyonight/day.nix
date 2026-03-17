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
      watchBackgroundColor = bg_search;
    };
    bg = "#e1e2e7";
    bg_dark = "#d0d5e3";
    bg_dark1 = "#c1c9df";
    bg_float = "#d0d5e3";
    bg_highlight = "#c4c8da";
    bg_popup = "#d0d5e3";
    bg_search = "#7890dd";
    bg_sidebar = "#d0d5e3";
    bg_statusline = "#d0d5e3";
    bg_visual = "#b7c1e3";
    black = "#b4b5b9";
    blue = "#2e7de9";
    blue0 = "#7890dd";
    blue1 = "#188092";
    blue2 = "#07879d";
    blue5 = "#006a83";
    blue6 = "#2e5857";
    blue7 = "#92a6d5";
    border = "#b4b5b9";
    border_highlight = "#4094a3";
    comment = "#848cb5";
    cyan = "#007197";
    dark3 = "#8990b3";
    dark5 = "#68709a";
    error = "#c64343";
    fg = "#3760bf";
    fg_dark = "#6172b0";
    fg_float = "#3760bf";
    fg_gutter = "#a8aecb";
    fg_sidebar = "#6172b0";
    green = "#587539";
    green1 = "#387068";
    green2 = "#38919f";
    hint = "#118c74";
    info = "#07879d";
    magenta = "#9854f1";
    magenta2 = "#d20065";
    orange = "#b15c00";
    purple = "#7847bd";
    red = "#f52a65";
    red1 = "#c64343";
    teal = "#118c74";
    bright_black = "#a1a6c5";
    bright_blue = "#358aff";
    bright_cyan = "#007ea8";
    bright_green = "#5c8524";
    bright_magenta = "#a463ff";
    bright_red = "#ff4774";
    white = "#6172b0";
    bright_white = "#3760bf";
    bright_yellow = "#a27629";
    terminal_black = "#a1a6c5";
    todo = "#2e7de9";
    warning = "#8c6c3e";
    yellow = "#8c6c3e";
  };
  cfg = config.my.theme.tokyonight;
  enable = cfg.enable && cfg.style == "day";
in
{
  config = mkIf enable {
    # my.theme.wallpaper = pkgs.fetchurl {
    #   url = "https://github.com/huwqchn/wallpapers/blob/main/tokyonight/Anime_girl.jpg";
    #   sha256 = "0irzajb3fi0f7x8vd6h55dsplkyl95p0vr9sigmlk46y673j6ksr";
    # };
    my.theme = {
      wallpaper = ./walls/Anime_girl.png;
      # I hated base16 scheme, so I made my own
      colorscheme = {
        inherit palette;
      };
    };
  };
}
