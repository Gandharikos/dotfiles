{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib.modules) mkDefault mkIf mkMerge;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  colorschemeEnable = config.nixporn.colorscheme == "tokyonight";
  enable = colorschemeEnable && osConfig.dot.gui.enable && isLinux;
in
{
  config = mkMerge [
    (mkIf colorschemeEnable {
      nixporn = {
        kvantum.enable = mkDefault false;
        qt5ct.enable = mkDefault false;
      };
    })
    (mkIf enable {
      home.packages = [ pkgs.catppuccin-kvantum ];

      qt = {
        enable = true;
        platformTheme.name = "qtct";
        style = {
          name = "kvantum";
        };
      };
    })
  ];
}
