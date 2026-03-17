{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.refactoring;
in
{
  options.my.neovim.lazyvim.refactoring = {
    enable = mkEnableOption "Refactoring tool";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        refactoring-nvim
      ];

      imports = [ "lazyvim.plugins.extras.editor.refactoring" ];
    };
  };
}
