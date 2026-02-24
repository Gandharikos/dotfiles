{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.my.desktop;
in {
  config = mkIf cfg.enable {
    programs = {
      # thunar file manager(part of xfce) related options
      thunar = {
        enable = true;
        plugins = [
          pkgs.thunar-archive-plugin
          pkgs.thunar-volman
        ];
      };
    };
  };
}
