{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.markdown;
in
{
  options.my.neovim.lazyvim.markdown = {
    enable = mkEnableOption "language markdown";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        markdown-preview-nvim
        render-markdown-nvim
        zk-nvim
      ];

      extraPackages = with pkgs; [
        markdownlint-cli2
        marksman
        imagemagick # for snacks.image
        typst # for snacks.image
        tectonic # for snacks.image
        ghostscript # for snacks.image
        mermaid-cli # for snacks.image
      ];

      config = [ "lang/markdown.lua" ];
    };
  };
}
