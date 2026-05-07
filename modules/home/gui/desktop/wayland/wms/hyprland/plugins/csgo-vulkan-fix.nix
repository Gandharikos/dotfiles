{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) int;
  inherit (lib.modules) mkIf;
  inherit (lib.lists) elem;
  inherit (config.dot.gui.desktop.hyprland) plugins;
  enable = plugins.enable && elem "csgo-vulkan-fix" plugins.list;
  cfg = config.dot.gui.desktop.hyprland.cs2fix;
in
{
  options.dot.gui.desktop.hyprland.cs2fix = {
    enable = mkEnableOption "Enable csgo-vulkan-fix" // {
      default = enable;
    };

    width = mkOption {
      type = int;
      default = 1920;
      description = "Width of the game window";
    };
    height = mkOption {
      type = int;
      default = 1080;
      description = "Height of the game window";
    };
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      plugins = with pkgs.hyprlandPlugins; [ csgo-vulkan-fix ];
      settings.plugin.csgo-vulkan-fix = {
        res_w = cfg.width;
        res_h = cfg.height;
        class = "cs2";
      };
    };
  };
}
