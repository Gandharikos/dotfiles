{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.edgy;
in
{
  options.my.lazyvim.edgy = {
    enable = mkEnableOption "edgy";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        edgy-nvim
      ];

      imports = [ "lazyvim.plugins.extras.ui.edgy" ];
    };
  };
}
