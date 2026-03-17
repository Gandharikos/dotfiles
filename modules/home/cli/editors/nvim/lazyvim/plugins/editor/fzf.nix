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
  config = mkIf (cfg.picker == "fzf") {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        fzf-lua
      ];
      excludePlugins = with pkgs.vimPlugins; [
        telescope-nvim
      ];
      imports = [ "lazyvim.plugins.editor.fzf" ];
    };
  };
}
