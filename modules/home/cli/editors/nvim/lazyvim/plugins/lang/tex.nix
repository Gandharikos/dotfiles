{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.tex;
in
{
  options.my.lazyvim.tex = {
    enable = mkEnableOption "language tex";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        vimtex
      ];

      imports = [ "lazyvim.plugins.extras.lang.tex" ];
    };
  };
}
