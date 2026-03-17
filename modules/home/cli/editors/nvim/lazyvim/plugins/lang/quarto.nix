{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.quarto;
in
{
  options.my.neovim.lazyvim.quarto = {
    enable = mkEnableOption "language quarto";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        quarto-nvim
        otter-nvim
        vim-slime
        jupytext-nvim
        img-clip-nvim
      ];

      config = [ "lang/quarto.lua" ];
    };
  };
}
