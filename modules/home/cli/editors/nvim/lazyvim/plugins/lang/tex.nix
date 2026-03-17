{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.tex;
in
{
  options.my.neovim.lazyvim.tex = {
    enable = mkEnableOption "language tex";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        vimtex
      ];

      imports = [ "lazyvim.plugins.extras.lang.tex" ];
    };
  };
}
