{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types) nullOr str;
  inherit (lib.my) runOnce isWayland;
  inherit (config.my.theme) wallpaper avatar;
  hyprlock' = runOnce pkgs "hyprlock";
  font_family = "SFProDisplay Nerd Font Bold";
  cfg = config.my.desktop.hyprlock;
  enable = config.my.desktop.lock == "hyprlock" && isWayland config;
in {
  options.my.desktop.hyprlock = {
    colors = {
      background = mkOption {
        type = nullOr str;
        default = "rgba(25, 20, 20, 1.0)";
        description = "The background color of the lock screen";
      };
      input_field = {
        outer = mkOption {
          type = nullOr str;
          default = "rgba(255, 255, 255, 0)";
          description = "The outer color of the input field";
        };
        inner = mkOption {
          type = nullOr str;
          default = "rgba(255, 255, 255, 0.1)";
          description = "The inner color of the input field";
        };
        font = mkOption {
          type = nullOr str;
          default = "rgb(200, 200, 200, 1)";
          description = "The font color of the input field";
        };
        placeholder = mkOption {
          type = nullOr str;
          default = "#ffffff99";
          description = "The placeholder color of the input field";
        };
      };
      label = {
        day = mkOption {
          type = nullOr str;
          default = "rgba(216, 222, 233, 0.70)";
          description = "The color of the day label";
        };
        month = mkOption {
          type = nullOr str;
          default = "rgba(216, 222, 233, 0.70)";
          description = "The color of the month label";
        };
        time = mkOption {
          type = nullOr str;
          default = "rgba(216, 222, 233, 0.70)";
          description = "The color of the time label";
        };
        user = mkOption {
          type = nullOr str;
          default = "rgba(216, 222, 233, 0.80)";
          description = "The color of the user label";
        };
        power = mkOption {
          type = nullOr str;
          default = "rgba(255, 255, 255, 0.60)";
          description = "The color of the power label";
        };
      };
      userbox = mkOption {
        type = nullOr str;
        default = "rgba(255, 255, 255, 0.1)";
        description = "The color of the user box";
      };
      userbox_border = mkOption {
        type = nullOr str;
        default = "rgba(255, 255, 255, 0)";
        description = "The color of the user shape";
      };
      avatar_border = mkOption {
        type = nullOr str;
        default = "rgba(255, 255, 255, 0.65)";
        description = "The color of the avatar border";
      };
    };
  };

  config = mkIf enable {
    wayland.windowManager.hyprland.settings = {
      bindd = [
        "SUPER ALT, L, Lock Screen, exec, ${hyprlock'}"
      ];
    };
    programs.hyprlock = {
      enable = true;

      settings = {
        general = {
          disable_loading_bar = true;
          hide_cursor = true;
          grace = 300;
        };

        background = [
          {
            monitor = "";
            path = "${wallpaper}";
            color = cfg.colors.background;
            blur_passes = 3;
            blur_size = 8;
            noise = 1.17e-2;
            contrast = 0.8916;
            vibrancy = 0.1696;
            vibrancy_darkness = 0.050;
          }
        ];

        input-field = [
          {
            monitor = "";
            size = "300, 60";
            outline_thickness = 2;

            outer_color = cfg.colors.input_field.outer;
            inner_color = cfg.colors.input_field.inner;
            font_color = cfg.colors.input_field.font;

            fade_on_empty = false;
            inherit font_family;
            placeholder_text = ''<i><span foreground="#${cfg.colors.input_field.placeholder}">🔒 Enter Password</span></i>'';

            dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
            dots_spacing = 0.2; # Scale of dots' absolute size, 0.0 - 1.0
            dots_center = true;

            hide_input = false;
            position = "0, -120";
            halign = "center";
            valign = "center";
          }
        ];

        image = [
          {
            monitor = "";
            path = "${avatar}";
            size = 130;
            rounding = -1;
            rotate = 0;
            border_size = 2;
            border_color = cfg.colors.avatar_border;
            halign = "center";
            valign = "center";
            position = "0, 40";
            shadow_passes = 1;
            reload_cmd = "";
            reload_time = -1;
          }
        ];
        shape = [
          {
            monitor = "";
            size = "300, 60";
            color = cfg.colors.userbox;
            rounding = -1;
            border_size = 0;
            border_color = cfg.colors.userbox_border;
            rotate = 0;
            xray = false;
            position = "0, -130";
            halign = "center";
            valign = "center";
          }
        ];

        label = [
          # day
          {
            monitor = "";
            text = ''cmd[update:1000] echo -e "$(date }"%A")"'';
            color = cfg.colors.label.day;
            font_size = 90;
            inherit font_family;
            position = "0, 350";
            halign = "center";
            valign = "center";
          }
          # month
          {
            monitor = "";
            text = ''cmd[update:1000] echo -e "$(date +"%d %B")"'';
            color = cfg.colors.label.month;
            font_size = 40;
            inherit font_family;
            position = "0, 50";
            valign = "center";
            halign = "center";
          }
          # time
          {
            monitor = "";
            text = ''cmd[update:1000] echo "<span>$(date +"- %I:%M -")</span>"'';
            color = cfg.colors.label.time;
            font_size = 20;
            inherit font_family;
            position = "0, 190";
            valign = "center";
            halign = "center";
          }
        ];
      };
    };
  };
}
