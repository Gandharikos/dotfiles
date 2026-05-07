{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.dot.theme) tokyonight colorscheme;

  cfg = tokyonight;
  enable = cfg.enable && config.console.enable;
  inherit (colorscheme) palette;

  stripHash = color: lib.substring 1 6 color;
in
{
  config = mkIf enable {
    console.colors = map (color: stripHash palette.${color}) [
      "black"
      "red"
      "green"
      "yellow"
      "blue"
      "magenta"
      "cyan"
      "fg_dark"

      "terminal_black"
      "bright_red"
      "bright_green"
      "bright_yellow"
      "bright_blue"
      "bright_magenta"
      "bright_cyan"
      "fg"
    ];
  };
}
