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
  enable = cfg.enable && config.my.git.enable && config.my.git.diff == "delta";
  inherit (config.my.theme.colorscheme) slug;
in
{
  config = mkIf enable {
    programs = {
      git.includes = [ { path = "${src}/extras/delta/${slug}.gitconfig"; } ];
      delta.options.features = slug;
    };
  };
}
