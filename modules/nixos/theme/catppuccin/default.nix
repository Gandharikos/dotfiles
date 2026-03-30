{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.my.theme.catppuccin;
in
{
  imports = [ inputs.catppuccin.nixosModules.catppuccin ];

  config = mkIf cfg.enable {
    catppuccin = {
      enable = true;
      inherit (cfg) flavor accent;
      cursors.enable = config.my.gui.enable && isLinux;
      grub.enable = false;
      plymouth.enable = false;
    };
  };
}
