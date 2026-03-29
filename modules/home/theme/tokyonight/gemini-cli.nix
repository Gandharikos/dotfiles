{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf importJSON;
  src = pkgs.vimPlugins.tokyonight-nvim;
  cfg = config.my.theme.tokyonight;
  enable = cfg.enable && config.my.gemini-cli.enable;
  inherit (config.my.theme.colorscheme) slug;

  themeConfig = importJSON "${src}/extras/gemini_cli/${slug}.json";
in
{
  config = mkIf enable {
    programs."gemini-cli".settings.ui = {
      theme = slug;
      customThemes."${slug}" = themeConfig // {
        type = "custom";
        name = slug;
      };
    };
  };
}
