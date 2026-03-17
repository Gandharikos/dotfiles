{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.mini-diff;
in
{
  options.my.neovim.lazyvim.mini-diff = {
    enable = mkEnableOption "Mini diff signs";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        {
          name = "mini.diff";
          path = mini-nvim;
        }
      ];

      imports = [ "lazyvim.plugins.extras.editor.mini-diff" ];
    };
  };
}
