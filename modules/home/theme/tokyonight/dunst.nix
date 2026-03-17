{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf importTOML;
  src = pkgs.vimPlugins.tokyonight-nvim;
  cfg = config.my.theme.tokyonight;
  inherit (config.my.theme.colorscheme) slug;
in
{
  config = mkIf cfg.enable {
    services.dunst.settings = importTOML "${src}/extras/dunst/${slug}.dunstrc";
  };
}
