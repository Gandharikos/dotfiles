{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.mini-animate;
in
{
  options.my.lazyvim.mini-animate = {
    enable = mkEnableOption "Mini animate";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      imports = [ "lazyvim.plugins.extras.ui.mini-animate" ];

      extraPlugins = with pkgs.vimPlugins; [
        {
          name = "mini.animate";
          path = mini-nvim;
        }
      ];
    };
  };
}
