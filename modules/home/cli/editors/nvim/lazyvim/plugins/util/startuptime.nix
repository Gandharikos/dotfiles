{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.startuptime;
in
{
  options.my.neovim.lazyvim.startuptime = {
    enable = mkEnableOption "startuptime";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        startuptime-nvim
      ];

      imports = [ "lazyvim.plugins.extras.util.startuptime" ];
    };
  };
}
