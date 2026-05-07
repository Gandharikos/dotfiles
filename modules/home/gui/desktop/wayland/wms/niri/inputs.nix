{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.dot.gui.desktop.niri;
in
{
  config = mkIf cfg.enable {
    programs.niri.settings.input = {
      workspace-auto-back-and-forth = true;
      keyboard = {
        repeat-rate = 25;
        repeat-delay = 200;
      };

      focus-follows-mouse = {
        enable = true;
        max-scroll-amount = "10%";
      };

      mouse = {
        accel-profile = "flat";
      };

      touchpad = {
        tap = true;
        dwt = true;
        drag = false;
        accel-speed = 0.2;
        accel-profile = "adaptive";
        natural-scroll = true;
        scroll-method = "two-finger";
        click-method = "clickfinger";
      };
    };
  };
}
