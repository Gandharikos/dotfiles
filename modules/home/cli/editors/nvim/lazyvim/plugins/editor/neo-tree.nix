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
  config = mkIf (cfg.explorer == "neo-tree") {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        neo-tree
      ];

      config = [ "editor/neo-tree.lua" ];
    };
  };
}
