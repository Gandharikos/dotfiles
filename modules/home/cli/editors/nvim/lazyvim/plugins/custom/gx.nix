{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.gx;
in
{
  options.my.neovim.lazyvim.gx = {
    enable = mkEnableOption "gx browse";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim.extraPlugins = with pkgs.vimPlugins; [
      gx-nvim
    ];

    my.neovim.lazyvim.config = [ "ui/gx.lua" ];
  };
}
