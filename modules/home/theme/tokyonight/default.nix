{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.theme.tokyonight;
  inherit (config.my.theme.colorscheme) slug;
in
{
  imports = lib.my.scanPaths ./.;

  config = mkIf cfg.enable {
    home.sessionVariables = {
      THEME = slug;
    };
  };
}
