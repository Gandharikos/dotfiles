{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.refactoring;
in
{
  options.my.lazyvim.refactoring = {
    enable = mkEnableOption "Refactoring tool";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        refactoring-nvim
      ];

      imports = [ "lazyvim.plugins.extras.editor.refactoring" ];
    };
  };
}
