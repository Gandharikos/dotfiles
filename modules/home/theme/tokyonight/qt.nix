{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.dot.theme.tokyonight;
  enable = cfg.enable && config.dot.gui.enable && isLinux;
in
{
  config = mkIf enable {
    home.packages = [ pkgs.catppuccin-kvantum ];

    qt = {
      enable = true;
      platformTheme.name = "qtct";
      style = {
        name = "kvantum";
      };
    };
  };
}
