{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.yanky;
in
{
  options.my.neovim.lazyvim.yanky = {
    enable = mkEnableOption "better yank/paste";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        yanky-nvim
      ];

      imports = [ "lazyvim.plugins.extras.coding.yanky" ];
    };
  };
}
