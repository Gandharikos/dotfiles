{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.gui.desktop.niri;
in
{
  config = mkIf cfg.enable {
    programs.niri.settings.animations = {
      workspace-switch.kind.spring = {
        damping-ratio = 0.8;
        stiffness = 520;
        epsilon = 0.0001;
      };

      horizontal-view-movement.kind.spring = {
        damping-ratio = 0.85;
        stiffness = 420;
        epsilon = 0.0001;
      };

      window-open.kind.easing = {
        duration-ms = 160;
        curve = "ease-out-expo";
      };

      window-close.kind.easing = {
        duration-ms = 140;
        curve = "ease-out-quad";
      };

      window-movement.kind.spring = {
        damping-ratio = 0.75;
        stiffness = 320;
        epsilon = 0.0001;
      };

      window-resize.kind.spring = {
        damping-ratio = 0.85;
        stiffness = 420;
        epsilon = 0.0001;
      };

      config-notification-open-close.kind.spring = {
        damping-ratio = 0.65;
        stiffness = 900;
        epsilon = 0.001;
      };

      screenshot-ui-open.kind.easing = {
        duration-ms = 200;
        curve = "ease-out-quad";
      };

      overview-open-close.kind.spring = {
        damping-ratio = 0.85;
        stiffness = 800;
        epsilon = 0.0001;
      };
    };
  };
}
