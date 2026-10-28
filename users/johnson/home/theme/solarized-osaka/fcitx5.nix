{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkForce mkIf;
  cfg = config.nixporn;
  inherit (cfg.colorschemes.solarized-osaka) polarity slug;
  classicUiFile = (pkgs.formats.iniWithGlobalSection { }).generate "fcitx5-classicui.conf" {
    globalSection = {
      Theme = slug;
      DarkTheme = slug;
      Font = "LXGW WenKai 13";
      MenuFont = "LXGW WenKai 10";
      TrayFont = "LXGW WenKai 10";
      UseDarkTheme = polarity == "dark";
      UseAccentColor = false;
    };
  };
in
{
  config = mkIf (cfg.colorscheme == "solarized-osaka" && cfg.fcitx5.enable && cfg.fcitx5.apply) {
    xdg.configFile."fcitx5/conf/classicui.conf" = mkForce {
      source = classicUiFile;
    };
  };
}
