{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim;
in
{
  config = mkIf (cfg.picker == "telescope") {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        telescope-nvim
        telescope-undo-nvim
        scope-nvim
      ];

      excludePlugins = with pkgs.vimPlugins; [
        fzf-lua
      ];

    };
  };
}
