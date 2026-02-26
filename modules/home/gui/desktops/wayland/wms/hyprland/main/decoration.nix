{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.my) vec2;
  cfg = config.my.desktop.hyprland;
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      decoration = {
        rounding = 19;
        rounding_power = 2.0;
        active_opacity = 0.9;
        inactive_opacity = 0.85;
        fullscreen_opacity = 0.95;
        dim_inactive = false;
        # dim_strength = 0.5;
        dim_special = 0.4;
        dim_around = 0.4;
        # screen_shader = ;
        # border_part_of_window = true;

        blur = {
          enabled = true;
          size = 13;
          passes = 3; # more passes = more resource intensive
          ignore_opacity = true;

          new_optimizations = true;
          xray = true;

          noise = 0.0117;
          contrast = 0.8916;
          brightness = 0.8172;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.1;

          special = false;
          popups = true;
          popups_ignorealpha = 0.2;

          input_methods = false;
          input_methods_ignorealpha = 0.2;
        };

        shadow = {
          enabled = true;
          range = 4;
          render_power = 4;
          sharp = false;
          ignore_window = true;
          offset = vec2 1 1;
          scale = 0.97;
        };
      };
    };
  };
}
