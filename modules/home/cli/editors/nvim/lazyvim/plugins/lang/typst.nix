{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.typst;
in
{
  options.my.neovim.lazyvim.typst = {
    enable = mkEnableOption "language typst";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      imports = [ "lazyvim.plugins.extras.lang.typst" ];

      extraPlugins = with pkgs.vimPlugins; [
        typst-preview-nvim
      ];
    };
  };
}
