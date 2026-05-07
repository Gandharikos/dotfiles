{
  config,
  lib,
  ...
}:
let
  inherit (config.dot) gui;
  inherit (lib.modules) mkIf;
in
{
  config = mkIf gui.enable {
    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [
          "JetBrainsMono Nerd Font Mono"
          "Maple Mono NF CN"

          # primary latin fallbacks
          "Source Code Pro"

          # CJK monospace (for Chinese users, prioritize SC)
          "Sarasa Mono SC"
          "Noto Sans Mono CJK SC"
          "Noto Sans Mono CJK TC"
          "Noto Sans Mono CJK JP"
          "Noto Sans Mono CJK KR"

          # unicode coverage
          "Noto Sans Mono"

          # icon fonts
          "Material Icons"
          "Material Design Icons"

          # final fallback
          "DejaVu Sans Mono"
        ];
        sansSerif = [
          # Primary Latin fonts
          "Inter"
          "Source Sans 3"

          # CJK sans-serif (macOS-like, prioritize SC for Chinese users)
          "LXGW WenKai"
          "Sarasa Gothic SC"
          "Noto Sans CJK SC"
          "Source Han Sans SC"
          "Noto Sans CJK TC"
          "Noto Sans CJK JP"
          "Noto Sans CJK KR"

          # Unicode coverage
          "Noto Sans"

          # Icons
          "Material Icons"
          "Material Design Icons"

          # Final fallback
          "DejaVu Sans"
        ];
        serif = [
          # Primary Latin serif
          "Source Serif 4"

          # CJK serif (prioritize SC)
          "LXGW WenKai"
          "Noto Serif CJK SC"
          "Source Han Serif SC"
          "Noto Serif CJK TC"
          "Noto Serif CJK JP"
          "Noto Serif CJK KR"

          # Unicode coverage
          "Noto Serif"

          # Icons
          "Material Icons"
          "Material Design Icons"

          # Final fallback
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
