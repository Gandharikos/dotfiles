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
  config = mkIf (cfg.explorer == "neo-tree") {
    my.lazyvim = {
      imports = [ "lazyvim.plugins.extras.editor.neo-tree" ];

      extraPlugins = with pkgs.vimPlugins; [
        neo-tree
      ];

    };
  };
}
