{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.harpoon;
in
{
  options.my.neovim.lazyvim.harpoon = {
    enable = mkEnableOption "harpoon2";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        harpoon
      ];

      imports = [ "lazyvim.plugins.extras.editor.harpoon2" ];
    };
  };
}
