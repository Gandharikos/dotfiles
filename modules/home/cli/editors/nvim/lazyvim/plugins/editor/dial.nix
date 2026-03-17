{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.dial;
in
{
  options.my.neovim.lazyvim.dial = {
    enable = mkEnableOption "Increment and decrement numbers, dates, and more";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        dial-nvim
      ];
      config = [ "coding/dial.lua" ];
    };
  };
}
