{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf mkMerge;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.my.theme.catppuccin;
  guiLinux = osConfig.dot.gui.enable && isLinux;
in
{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
  ]
  ++ lib.dot.scanPaths ./.;

  config = mkIf cfg.enable (mkMerge [
    {
      catppuccin = {
        enable = true;
        inherit (cfg) flavor accent;
        wezterm.apply = true;
        # Disable nvim integration - we configure it manually via LazyVim
        nvim.enable = false;
      };

      home.sessionVariables = {
        COLORSCHEME_FLAVOR = cfg.flavor;
        COLORSCHEME_ACCENT = cfg.accent;
      };
    }
    (mkIf guiLinux {
      catppuccin.cursors.enable = true;

      home.pointerCursor = {
        size = 24;
        gtk.enable = true;
        x11.enable = true;
      };
    })
  ]);
}
