{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.rest;
in
{
  options.my.lazyvim.rest = {
    enable = mkEnableOption "rest tool";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        kulala-nvim
      ];

      imports = [ "lazyvim.plugins.extras.util.rest" ];
    };
  };
}
