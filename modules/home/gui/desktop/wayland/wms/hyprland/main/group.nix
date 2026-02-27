{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.my.desktop.hyprland;
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      group = {
        merge_floated_into_tiled_on_groupbar = true;
        groupbar = {
          enabled = true;
          font_family = "Maple Mono";
          font_size = 8;
          gradients = true;
          height = 12;
          indicator_height = 3;
          # stacked = true;
          gaps_in = 2;
          gaps_out = 2;
          # key_upper_gap = true;
        };
      };
    };
  };
}
