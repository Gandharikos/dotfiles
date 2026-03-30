{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.theme.catppuccin;
in
{
  config = mkIf (cfg.enable && config.my.tmux.enable) {
    catppuccin.tmux.extraConfig = ''
      set -g @catppuccin_status_background "none"
    '';
  };
}
