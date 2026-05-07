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
  inherit (config.dot.theme.colorscheme) slug;
in
{
  config = mkIf cfg.enable {
    programs.bat = {
      config.theme = slug;
      themes."${slug}" = {
        inherit src;
        file = "extras/sublime/${slug}.tmTheme";
      };
    };
  };
}
