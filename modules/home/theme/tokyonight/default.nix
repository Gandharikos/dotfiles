{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.theme.tokyonight;
in
{
  imports = lib.my.scanPaths ./.;

  config = mkIf cfg.enable {
    home.sessionVariables.COLORSCHEME_STYLE = cfg.style;
  };
}
