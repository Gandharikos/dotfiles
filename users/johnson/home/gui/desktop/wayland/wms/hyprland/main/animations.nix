{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.gui.desktop.hyprland;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      animations = {
        enabled = true;

        # name, x0, y0, x1, y1
        # x0 and x1 are control animation speed
        # y0 and y1 are control animation duration
        bezier = [
          "overshot,0.13,0.99,0.29,1.1"
          "bounceback,0.1,1.4,0.2,1.0"
          "elastic,0.32,1.56,0.68,1.0"
          "jelly,0.34,1.56,0.64,0.8"
          "linear,0,0,1,1"

          "smoothOut, 0.36, 0, 0.66, -0.56"
          "smoothIn, 0.25, 1, 0.5, 1"
          "fluent_decel, 0, 0.2, 0.4, 1"
          "easeOutCirc, 0, 0.55, 0.45, 1"
          "easeOutCubic, 0.33, 1, 0.68, 1"
          "easeinoutsine, 0.37, 0, 0.63, 1"
          # "snappy, 0.5, 0.93, 0, 1"
        ];
        animation = [
          "windows,1,6,jelly,popin 80%"
          "windowsMove,1,6,overshot,slide"
          "layers,1,10,bounceback,slide"
          "fadeIn,1,10,smoothIn"
          "fadeOut,1,10,smoothOut"
          "fadeSwitch, 1, 5, easeOutCirc" # fade on changing activewindow and its opacity
          "fadeShadow, 1, 5, easeOutCirc" # fade on changing activewindow for shadows
          "fadeDim, 1, 6, fluent_decel" # the easing of the dimming of inactive windows
          "workspaces,1,8.8,overshot,slidefade"
          "specialWorkspace, 1, 3, fluent_decel, slidevert"
          "border,1,5,linear"
          "borderangle,1,60,linear,loop"
        ];
      };
    };
  };
}
