{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.octo;
in
{
  options.my.neovim.lazyvim.octo = {
    enable = mkEnableOption "octo";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        octo-nvim
      ];

      imports = [ "lazyvim.plugins.extras.util.octo" ];
    };
  };
}
