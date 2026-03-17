{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.mini-comment;
in
{
  options.my.neovim.lazyvim.mini-comment = {
    enable = mkEnableOption "Comment tool - mini.comment";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        {
          name = "mini.comment";
          path = mini-nvim;
        }
        nvim-ts-context-commentstring
      ];

      imports = [ "lazyvim.plugins.extras.coding.mini-comment" ];
    };
  };
}
