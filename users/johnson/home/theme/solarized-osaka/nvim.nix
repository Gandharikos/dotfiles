{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.nixporn.colorschemes.solarized-osaka;
  enable =
    config.nixporn.colorscheme == "solarized-osaka"
    && config.my.neovim.enable
    && config.my.neovim.distro == "lazyvim";
in
{
  config = mkIf enable {
    home.sessionVariables = {
      COLORSCHEME_VARIANT = cfg.variant;
      COLORSCHEME_TRANSPARENT = if config.nixporn.transparent then "true" else "false";
    };

    programs.lazyvim.extraPlugins = [ pkgs.vimPlugins.solarized-osaka-nvim ];
  };
}
