{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.mini-surround;
in
{
  options.my.lazyvim.mini-surround = {
    enable = mkEnableOption "Fast and feature-rich surround actions";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        {
          name = "mini.surround";
          path = mini-nvim;
        }
      ];

      imports = [ "lazyvim.plugins.extras.coding.mini-surround" ];
    };
  };
}
