{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.clojure;
in
{
  options.my.lazyvim.clojure = {
    enable = mkEnableOption "language clojure";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins =
        with pkgs.vimPlugins;
        [
          nvim-treesitter-sexp
          baleia-nvim
          conjure
        ]
        ++ lib.optionals (config.my.lazyvim.cmp == "nvim-cmp") [ cmp-conjure ];

      imports = [ "lazyvim.plugins.extras.lang.clojure" ];

      extraPackages = with pkgs; [
        astro-language-server
      ];
    };
  };
}
