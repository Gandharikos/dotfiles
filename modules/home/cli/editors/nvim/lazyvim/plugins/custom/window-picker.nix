{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.window-picker;
in
{
  options.my.neovim.lazyvim.window-picker = {
    enable = mkEnableOption "window picker";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        nvim-window-picker
      ];

      config = [ "ui/window-picker.lua" ];
    };
  };
}
