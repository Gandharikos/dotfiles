{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.luasnip;
in
{
  options.my.lazyvim.luasnip = {
    enable = mkEnableOption "Code snippet engine - LuaSnip";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins =
        with pkgs.vimPlugins;
        [
          LuaSnip
        ]
        ++ lib.optionals (config.my.lazyvim.cmp == "nvim-cmp") [ cmp_luasnip ];

      excludePlugins = with pkgs.VimPlugins; [
        nvim-snippets
      ];

    };
  };
}
