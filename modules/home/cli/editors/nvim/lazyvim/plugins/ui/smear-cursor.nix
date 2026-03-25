{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.smear-cursor;
in
{
  options.my.lazyvim.smear-cursor = {
    enable = mkEnableOption "animate cursor";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        smear-cursor-nvim
      ];

      imports = [ "lazyvim.plugins.extras.ui.smear-cursor" ];
    };
  };
}
