{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.overseer;
in
{
  options.my.neovim.lazyvim.overseer = {
    enable = mkEnableOption "overseer";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        overseer-nvim
      ];

      imports = [ "lazyvim.plugins.extras.editor.overseer" ];
    };
  };
}
