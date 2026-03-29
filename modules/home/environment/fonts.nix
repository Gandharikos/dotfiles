{
  config,
  lib,
  ...
}:
let
  inherit (config.my) gui;
  inherit (lib.modules) mkIf;
in
{
  config = mkIf gui.enable {
    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [
          "JetBrainsMono Nerd Font Mono"

          # primary latin fallbacks
          "Source Code Pro"

          # unicode coverage
          "Noto Sans Mono"
          "Noto Sans"
          "Noto Serif"

          # CJK coverage
          "Noto Sans CJK JP"
          "Noto Sans CJK SC"
          "Noto Sans CJK TC"
          "Noto Sans CJK KR"

          # icon fonts
          "Material Icons"
          "Material Design Icons"

          # final fallback
          "DejaVu Sans Mono"
        ];
        sansSerif = [
          "JetBrainsMono Nerd Font"

          # primary latin fallbacks
          "Inter"
          "Source Sans 3"

          # unicode coverage
          "Noto Sans"

          # CJK
          "Noto Sans CJK JP"
          "Noto Sans CJK SC"
          "Noto Sans CJK TC"
          "Noto Sans CJK KR"

          # icons
          "Material Icons"
          "Material Design Icons"

          # final fallback
          "DejaVu Sans"
        ];
        serif = [
          "JetBrainsMono Nerd Font"

          # latin serif
          "Source Serif 4"

          # unicode coverage
          "Noto Serif"

          # CJK
          "Noto Serif CJK JP"
          "Noto Serif CJK SC"
          "Noto Serif CJK TC"
          "Noto Serif CJK KR"

          # icons
          "Material Icons"
          "Material Design Icons"

          # final fallback
          "DejaVu Serif"
        ];
        emoji = [
          "Twemoji Color Font"
          "Noto Color Emoji"
        ];
      };
    };
  };
}
