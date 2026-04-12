{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.my) gui;
  inherit (lib.modules) mkIf;
in
{
  config = mkIf gui.enable {
    fonts.packages = with pkgs; [
      # icon fonts
      twemoji-color-font
      noto-fonts-color-emoji
      material-icons
      material-design-icons
      font-awesome

      # Latin fonts
      source-sans
      source-serif
      inter

      # Chinese fonts (macOS-like experience)
      # LXGW WenKai: Modern Chinese font, closest open-source alternative to PingFang
      lxgw-wenkai
      # Sarasa Gothic: High-quality CJK font with excellent hinting
      sarasa-gothic

      # Fallback CJK fonts
      source-han-sans
      source-han-serif
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif

      # Nerdfonts
      nerd-fonts.symbols-only
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.iosevka
      nerd-fonts.caskaydia-cove

      # Maple Mono (Chinese-friendly monospace)
      maple-mono.variable
      maple-mono.truetype
      maple-mono.NF
      maple-mono.NF-CN

      # Other fonts
      julia-mono
      dejavu_fonts
      # inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd
    ];
  };
}
