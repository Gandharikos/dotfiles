{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim;
in
{
  config = mkIf (cfg.picker == "telescope") {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        telescope-nvim
        telescope-undo-nvim
        scope-nvim
      ];

      excludePlugins = with pkgs.vimPlugins; [
        fzf-lua
      ];

      config = [ "editor/telescope.lua" ];
    };
  };
}
