{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.overseer;
in
{
  options.my.lazyvim.overseer = {
    enable = mkEnableOption "overseer";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        overseer-nvim
      ];

      imports = [ "lazyvim.plugins.extras.editor.overseer" ];
    };
  };
}
