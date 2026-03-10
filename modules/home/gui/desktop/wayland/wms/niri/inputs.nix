{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.my.gui.desktop.niri;
in {
  config = mkIf cfg.enable {
    programs.niri.settings.input = {
      keyboard = {
        xkb = {
          layout = "us";
          options = "ctrl:nocaps";
        };
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
        accel-speed = 0.2;
        accel-profile = "adaptive";
        natural-scroll = true;
        click-method = "clickfinger";
      };
    };
  };
}
