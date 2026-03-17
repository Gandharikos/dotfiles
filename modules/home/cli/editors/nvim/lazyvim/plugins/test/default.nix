{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.test;
in
{
  options.my.neovim.lazyvim.test = {
    enable = mkEnableOption "Neotest support";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        neotest
      ];

      imports = [ "lazyvim.plugins.extras.test.core" ];
    };
  };
}
