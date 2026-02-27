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
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_move_enables_dpms = true;
        enable_swallow = false;
        swallow_regex = "^(org.wezfurlong.wezterm)$";
        # enable variable refresh rate (effective depending on hardware)
        # 0: disable, 1: enable, 2: only enaleb when fullscreen
        vrr = 2;
        vfr = true;
      };
    };
  };
}
