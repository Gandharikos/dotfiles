{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.octo;
in
{
  options.my.lazyvim.octo = {
    enable = mkEnableOption "octo";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        octo-nvim
      ];

      imports = [ "lazyvim.plugins.extras.util.octo" ];
    };
  };
}
