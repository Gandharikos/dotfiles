{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.my.theme.general) transparent;
  src = pkgs.vimPlugins.tokyonight-nvim;
  cfg = config.my.theme.tokyonight;
  enable = cfg.enable && config.my.btop.enable;
  inherit (config.my.theme.colorscheme) slug;
in
{
  config = mkIf enable {
    programs.btop.settings = {
      color_theme = slug;
      theme_background = transparent; # make it transparent
    };

    xdg.configFile."btop/themes/${slug}.theme".source = "${src}/extras/btop/${slug}.theme";
  };
}
