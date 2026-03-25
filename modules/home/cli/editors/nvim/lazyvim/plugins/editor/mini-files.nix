{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.mini-files;
in
{
  options.my.lazyvim.mini-files = {
    enable = mkEnableOption "Mini files explorer";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      imports = [ "lazyvim.plugins.extras.editor.mini-files" ];

      extraPlugins = with pkgs.vimPlugins; [
        {
          name = "mini.files";
          path = mini-nvim;
        }
      ];

    };
  };
}
