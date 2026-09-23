{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.nixporn.colorschemes.kanagawa;
  enable =
    config.nixporn.colorscheme == "kanagawa"
    && config.my.neovim.enable
    && config.my.neovim.distro == "lazyvim";
in
{
  config = mkIf enable {
    home.sessionVariables = {
      COLORSCHEME_VARIANT = cfg.variant;
      COLORSCHEME_TRANSPARENT = if config.nixporn.transparent then "true" else "false";
    };

    programs.lazyvim.extraPlugins = [ pkgs.vimPlugins.kanagawa-nvim ];
  };
}
