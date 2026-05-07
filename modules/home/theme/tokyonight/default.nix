{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.dot.theme.tokyonight;
in
{
  imports = lib.dot.scanPaths ./.;

  config = mkIf cfg.enable {
    home.sessionVariables.COLORSCHEME_STYLE = cfg.style;
  };
}
