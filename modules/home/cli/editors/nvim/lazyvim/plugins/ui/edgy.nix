{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.edgy;
in
{
  options.my.neovim.lazyvim.edgy = {
    enable = mkEnableOption "edgy";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        edgy-nvim
      ];

      imports = [ "lazyvim.plugins.extras.ui.edgy" ];
    };
  };
}
