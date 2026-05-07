{
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (config.my.theme.colorscheme) palette;
  cfg = config.my.theme.catppuccin;
  enable = cfg.enable && osConfig.dot.gui.enable && isLinux && config.my.gui.desktop.niri.enable;
  accent = palette.${cfg.accent};
in
{
  config = mkIf enable {
    programs.niri.settings.layout = {
      background-color = palette.base;
      border = {
        active.color = accent;
        inactive.color = palette.surface0;
        urgent.color = palette.red;
      };
      focus-ring = {
        active.color = accent;
        inactive.color = palette.surface0;
        urgent.color = palette.red;
      };
    };
  };
}
