{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.luasnip;
in
{
  options.my.neovim.lazyvim.luasnip = {
    enable = mkEnableOption "Code snippet engine - LuaSnip";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins =
        with pkgs.vimPlugins;
        [
          LuaSnip
        ]
        ++ lib.optionals (config.my.neovim.lazyvim.cmp == "nvim-cmp") [ cmp_luasnip ];

      excludePlugins = with pkgs.VimPlugins; [
        nvim-snippets
      ];

      imports = [ "lazyvim.plugins.extras.coding.luasnip" ];
    };
  };
}
