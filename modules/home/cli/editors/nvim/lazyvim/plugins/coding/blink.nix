{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim;
in
{
  config = mkIf (cfg.cmp == "auto" || cfg.cmp == "blink") {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        blink-cmp
        blink-compat
        friendly-snippets
      ];

      excludePlugins = with pkgs.vimPlugins; [
        nvim-cmp
      ];
    };
  };
}
