{
  inputs,
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkDefault mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.nixporn.colorschemes.solarized-osaka;
  enable = config.nixporn.colorscheme == "solarized-osaka" && isLinux && osConfig.dot.gui.enable;
in
{
  imports = lib.dot.scanPaths ./.;

  config = mkIf enable {
    nixporn.wallpaper = mkDefault inputs.wallpapers.solarized.chinatown.path;

    home.sessionVariables.HYPRCURSOR_SIZE = toString config.home.pointerCursor.size;

    gtk = {
      iconTheme = {
        name = if cfg.polarity == "light" then "Papirus-Light" else "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      gtk3.extraConfig.gtk-application-prefer-dark-theme = cfg.polarity == "dark";
      gtk4.extraConfig.gtk-application-prefer-dark-theme = cfg.polarity == "dark";
    };

    qt = {
      enable = true;
      platformTheme.name = "qtct";
      style.name = "kvantum";
    };
  };
}
