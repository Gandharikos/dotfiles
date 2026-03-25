{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.mini-snippets;
in
{
  options.my.lazyvim.mini-snippets = {
    enable = mkEnableOption "Code snippet engine - mini-snippets";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins =
        with pkgs.vimPlugins;
        [
          {
            name = "mini.snippets";
            path = mini-nvim;
          }
          friendly-snippets
        ]
        ++ lib.optionals (config.my.lazyvim.cmp == "nvim-cmp") [ cmp-mini-snippets ];

      excludePlugins = with pkgs.vimPlugins; [
        nvim-snippets
      ];

      imports = [ "lazyvim.plugins.extras.coding.mini-snippets" ];
    };
  };
}
