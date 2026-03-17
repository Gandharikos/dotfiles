{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.mini-surround;
in
{
  options.my.neovim.lazyvim.mini-surround = {
    enable = mkEnableOption "Fast and feature-rich surround actions";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        {
          name = "mini.surround";
          path = mini-nvim;
        }
      ];

      config = [ "coding/mini-surround.lua" ];
    };
  };
}
