{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.mini-comment;
in
{
  options.my.lazyvim.mini-comment = {
    enable = mkEnableOption "Comment tool - mini.comment";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
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
