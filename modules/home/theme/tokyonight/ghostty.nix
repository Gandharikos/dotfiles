{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  src = pkgs.vimPlugins.tokyonight-nvim;
  cfg = config.my.theme.tokyonight;
  inherit (config.my.theme.colorscheme) slug;
in
{
  config = mkIf cfg.enable {
    programs.ghostty.settings.theme = "${src + "/extras/ghostty/" + slug}";
  };
}
