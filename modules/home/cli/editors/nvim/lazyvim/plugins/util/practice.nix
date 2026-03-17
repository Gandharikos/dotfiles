{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.practice;
in
{
  options.my.neovim.lazyvim.practice = {
    enable = mkEnableOption "Practice plugin";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        hardtime-nvim
        precognition-nvim
      ];

      config = [ "util/practice.lua" ];
    };
  };
}
