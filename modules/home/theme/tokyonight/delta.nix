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
  enable = cfg.enable && config.dot.git.enable && config.dot.git.diff == "delta";
  inherit (config.dot.theme.colorscheme) slug;
in
{
  config = mkIf enable {
    programs = {
      git.includes = [ { path = "${src}/extras/delta/${slug}.gitconfig"; } ];
      delta.options.features = slug;
    };
  };
}
