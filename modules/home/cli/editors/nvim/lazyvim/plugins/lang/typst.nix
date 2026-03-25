{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.typst;
in
{
  options.my.lazyvim.typst = {
    enable = mkEnableOption "language typst";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      imports = [ "lazyvim.plugins.extras.lang.typst" ];

      extraPlugins = with pkgs.vimPlugins; [
        typst-preview-nvim
      ];
    };
  };
}
