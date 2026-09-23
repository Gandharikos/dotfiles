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
  enable = config.nixporn.colorscheme == "kanagawa" && isLinux && osConfig.dot.gui.enable;
in
{
  imports = lib.dot.scanPaths ./.;

  config = mkIf enable {
    nixporn.wallpaper = mkDefault inputs.wallpapers.kanagawa.mountain-dragon.path;
  };
}
