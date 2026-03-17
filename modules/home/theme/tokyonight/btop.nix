{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.my.theme.general) transparent;
  cfg = config.my.theme.tokyonight;
in
{
  config = mkIf cfg.enable {
    programs.btop.settings = {
      color_theme = "tokyo-night";
      theme_background = transparent; # make it transparent
    };
  };
}
