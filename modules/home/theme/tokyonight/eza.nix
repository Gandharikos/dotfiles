{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  src = pkgs.vimPlugins.tokyonight-nvim;
  cfg = config.dot.theme.tokyonight;
  enable = cfg.enable && config.dot.eza.enable;
  inherit (config.dot.theme.colorscheme) slug;
in
{
  config = mkIf enable {
    home.sessionVariables.EZA_CONFIG_DIR = lib.mkDefault "${config.xdg.configHome}/eza";

    xdg.configFile."eza/theme.yml".source = "${src}/extras/eza/${slug}.yml";
  };
}
