{
  lib,
  config,
  inputs,
  themeNamespace ? "dot",
  ...
}:
let
  inherit (lib.modules) mkIf;
  palette = rec {
    cursor = {
      baseColor = teal;
      outlineColor = bg_highlight;
      watchBackgroundColor = purple;
    };
    bg = "#24283b";
    bg_dark = "#1f2335";
    bg_dark1 = "#1b1e2d";
    bg_float = "#1f2335";
    bg_highlight = "#292e42";
    bg_popup = "#1f2335";
    bg_search = "#3d59a1";
    bg_sidebar = "#1f2335";
    bg_statusline = "#1f2335";
    bg_visual = "#2e3c64";
    black = "#1d202f";
    blue = "#7aa2f7";
    blue0 = "#3d59a1";
    blue1 = "#2ac3de";
    blue2 = "#0db9d7";
    blue5 = "#89ddff";
    blue6 = "#b4f9f8";
    blue7 = "#394b70";
    border = "#1d202f";
    border_highlight = "#29a4bd";
    comment = "#565f89";
    cyan = "#7dcfff";
    dark3 = "#545c7e";
    dark5 = "#737aa2";
    error = red1;
    fg = "#c0caf5";
    fg_dark = "#a9b1d6";
    fg_float = "#c0caf5";
    fg_gutter = "#3b4261";
    fg_sidebar = "#a9b1d6";
    green = "#9ece6a";
    green1 = "#73daca";
    green2 = "#41a6b5";
    hint = "#1abc9c";
    info = "#0db9d7";
    magenta = "#bb9af7";
    magenta2 = "#ff007c";
    none = "NONE";
    orange = "#ff9e64";
    purple = "#9d7cd8";
    red = "#f7768e";
    red1 = "#db4b4b";
    teal = "#1abc9c";
    bright_black = "#414868";
    bright_blue = "#8db0ff";
    bright_cyan = "#a4daff";
    bright_green = "#9fe044";
    bright_magenta = "#c7a9ff";
    bright_red = "#ff899d";
    white = "#a9b1d6";
    bright_white = "#c0caf5";
    bright_yellow = "#faba4a";
    terminal_black = "#414868";
    todo = "#7aa2f7";
    warning = yellow;
    yellow = "#e0af68";
  };
  namespace = themeNamespace;
  cfg = config.${namespace}.theme.tokyonight;
  enable = cfg.enable && cfg.style == "storm";
in
{
  config = mkIf enable {
    ${namespace}.theme = {
      wallpaper = inputs.wallpapers.tokyonight.tokyo-night-street-rain.path;
      # I hated base16 scheme, so I made my own
      colorscheme = {
        inherit palette;
      };
    };
  };
}
