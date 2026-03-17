{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.mini-move;
in
{
  options.my.neovim.lazyvim.mini-move = {
    enable = mkEnableOption "Mini move";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        {
          name = "mini.move";
          path = mini-nvim;
        }
      ];

      config = [ "editor/mini-move.lua" ];
    };
  };
}
