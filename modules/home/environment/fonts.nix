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
    # Additional fontconfig XML rules for better CJK rendering
    home.file.".config/fontconfig/conf.d/99-chinese-fonts.conf".text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <!-- Prefer SC (Simplified Chinese) variants for Chinese locale -->
        <match target="pattern">
          <test qual="any" name="family">
            <string>sans-serif</string>
          </test>
          <edit name="family" mode="prepend" binding="strong">
            <string>LXGW WenKai</string>
            <string>Sarasa Gothic SC</string>
            <string>Noto Sans CJK SC</string>
          </edit>
        </match>

        <match target="pattern">
          <test qual="any" name="family">
            <string>serif</string>
          </test>
          <edit name="family" mode="prepend" binding="strong">
            <string>Noto Serif CJK SC</string>
            <string>Source Han Serif SC</string>
          </edit>
        </match>

        <match target="pattern">
          <test qual="any" name="family">
            <string>monospace</string>
          </test>
          <edit name="family" mode="prepend" binding="strong">
            <string>Maple Mono NF CN</string>
            <string>Sarasa Mono SC</string>
          </edit>
        </match>

        <!-- Rendering quality settings for better appearance -->
        <match target="font">
          <test name="family" compare="contains">
            <string>Noto Sans CJK</string>
          </test>
          <edit name="hinting" mode="assign">
            <bool>true</bool>
          </edit>
          <edit name="hintstyle" mode="assign">
            <const>hintslight</const>
          </edit>
          <edit name="antialias" mode="assign">
            <bool>true</bool>
          </edit>
          <edit name="rgba" mode="assign">
            <const>rgb</const>
          </edit>
        </match>

        <match target="font">
          <test name="family" compare="contains">
            <string>LXGW WenKai</string>
          </test>
          <edit name="hinting" mode="assign">
            <bool>true</bool>
          </edit>
          <edit name="hintstyle" mode="assign">
            <const>hintslight</const>
          </edit>
          <edit name="antialias" mode="assign">
            <bool>true</bool>
          </edit>
        </match>
      </fontconfig>
    '';

    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [
          "Maple Mono NF CN"
          "JetBrainsMono Nerd Font Mono"

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
