{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.clojure;
in
{
  options.my.neovim.lazyvim.clojure = {
    enable = mkEnableOption "language clojure";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins =
        with pkgs.vimPlugins;
        [
          nvim-treesitter-sexp
          baleia-nvim
          conjure
        ]
        ++ lib.optionals (config.my.neovim.lazyvim.cmp == "nvim-cmp") [ cmp-conjure ];

      imports = [ "lazyvim.plugins.extras.lang.clojure" ];

      extraPackages = with pkgs; [
        astro-language-server
      ];
    };
  };
}
