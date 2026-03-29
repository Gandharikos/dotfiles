{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  src = pkgs.vimPlugins.tokyonight-nvim;
  cfg = config.my.theme.tokyonight;
  enable = cfg.enable && config.my.eza.enable;
  inherit (config.my.theme.colorscheme) slug;
in
{
  config = mkIf enable {
    home.sessionVariables.EZA_CONFIG_DIR = lib.mkDefault "${config.xdg.configHome}/eza";

    xdg.configFile."eza/theme.yml".source = "${src}/extras/eza/${slug}.yml";
  };
}
