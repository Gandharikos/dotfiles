{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf mkMerge;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (config.my.theme.colorscheme) slug;
  cfg = config.my.theme.catppuccin;
  guiLinux = config.my.gui.enable && isLinux;
in
{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
  ]
  ++ lib.my.scanPaths ./.;

  config = mkIf cfg.enable (mkMerge [
    {
      catppuccin = {
        enable = true;
        inherit (cfg) flavor accent;
        wezterm.apply = true;
      };

      home.sessionVariables.THEME = slug;
    }
    (mkIf guiLinux {
      catppuccin.cursors.enable = true;
      catppuccin.fcitx5 = {
        enable = true;
        enableRounded = true;
      };

      home.pointerCursor = {
        size = 24;
        gtk.enable = true;
        x11.enable = true;
      };
    })
  ]);
}
