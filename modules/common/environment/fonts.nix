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

      noto-fonts-color-emoji

      source-sans
      source-serif
      source-han-sans
      source-han-serif

      # fonts for none latin languages
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif

      # nerdfonts
      nerd-fonts.symbols-only
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.iosevka
      nerd-fonts.caskaydia-cove

      # maple-mono
      maple-mono.variable
      maple-mono.truetype
      maple-mono.NF
      maple-mono.NF-CN

      julia-mono
      dejavu_fonts
      inter
      # inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd
    ];
  };
}
