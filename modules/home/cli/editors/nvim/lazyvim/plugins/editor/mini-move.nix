{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.mini-move;
in
{
  options.my.lazyvim.mini-move = {
    enable = mkEnableOption "Mini move";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      imports = [ "lazyvim.plugins.extras.editor.mini-move" ];

      extraPlugins = with pkgs.vimPlugins; [
        {
          name = "mini.move";
          path = mini-nvim;
        }
      ];

    };
  };
}
