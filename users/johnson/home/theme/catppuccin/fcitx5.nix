{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkForce mkIf;
  cfg = config.nixporn;
  inherit (cfg.colorschemes) catppuccin;
  inherit (catppuccin) accent flavor;
  themeName = "catppuccin-${flavor}-${accent}";
  classicUiFile = (pkgs.formats.iniWithGlobalSection { }).generate "fcitx5-classicui.conf" {
    globalSection = {
      Theme = themeName;
      DarkTheme = themeName;
      Font = "LXGW WenKai 13";
      MenuFont = "LXGW WenKai 10";
      TrayFont = "LXGW WenKai 10";
      UseDarkTheme = true;
      UseAccentColor = false;
    };
  };
in
{
  config = mkIf (cfg.colorscheme == "catppuccin" && cfg.fcitx5.enable && cfg.fcitx5.apply) {
    xdg.configFile."fcitx5/conf/classicui.conf" = mkForce {
      source = classicUiFile;
    };
  };
}
