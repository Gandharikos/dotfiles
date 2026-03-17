{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.mini-animate;
in
{
  options.my.neovim.lazyvim.mini-animate = {
    enable = mkEnableOption "Mini animate";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        {
          name = "mini.animate";
          path = mini-nvim;
        }
      ];
      config = [ "ui/mini-animate.lua" ];
    };
  };
}
