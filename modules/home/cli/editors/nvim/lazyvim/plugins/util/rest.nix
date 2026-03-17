{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.rest;
in
{
  options.my.neovim.lazyvim.rest = {
    enable = mkEnableOption "rest tool";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        kulala-nvim
      ];

      imports = [ "lazyvim.plugins.extras.util.rest" ];
    };
  };
}
