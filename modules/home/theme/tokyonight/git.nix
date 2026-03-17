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
  inherit (config.my.theme.colorscheme) slug;
in
{
  config = mkIf cfg.enable {
    programs = {
      git.includes = [ { path = "${src}/extras/delta/${slug}.gitconfig"; } ];
      delta.options.features = slug;
    };
  };
}
