{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.mini-hipatterns;
in
{
  options.my.lazyvim.mini-hipatterns = {
    enable = mkEnableOption "Highlight colors in your code";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        {
          name = "mini.hipatterns";
          path = mini-nvim;
        }
      ];

      imports = [ "lazyvim.plugins.extras.util.mini-hipatterns" ];
    };
  };
}
