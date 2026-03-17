{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.obsidian;
in
{
  options.my.neovim.lazyvim.obsidian = {
    enable = mkEnableOption "Obsidian plugin for LazyVim";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        obsidian-nvim
      ];
      config = [ "util/obsidian.lua" ];
    };
  };
}
