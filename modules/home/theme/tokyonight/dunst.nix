{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf importTOML;
  src = pkgs.vimPlugins.tokyonight-nvim;
  cfg = config.dot.theme.tokyonight;
  inherit (config.dot.theme.colorscheme) slug;
in
{
  config = mkIf cfg.enable {
    services.dunst.settings = importTOML "${src}/extras/dunst/${slug}.dunstrc";
  };
}
