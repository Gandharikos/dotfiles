{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.harpoon;
in
{
  options.my.lazyvim.harpoon = {
    enable = mkEnableOption "harpoon2";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        harpoon
      ];

      imports = [ "lazyvim.plugins.extras.editor.harpoon2" ];
    };
  };
}
