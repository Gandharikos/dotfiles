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
  config = mkIf (cfg.picker == "fzf") {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        fzf-lua
      ];
      excludePlugins = with pkgs.vimPlugins; [
        telescope-nvim
      ];
      imports = [ "lazyvim.plugins.editor.fzf" ];
    };
  };
}
