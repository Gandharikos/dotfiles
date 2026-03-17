{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.winshift;
in
{
  options.my.neovim.lazyvim.winshift = {
    enable = mkEnableOption "window winshift";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [ winshift-nvim ];

      config = [ "ui/winshift.lua" ];
    };
  };
}
