{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.my.desktop.niri;
in {
  config = mkIf cfg.enable {
    programs.niri.settings.animations = {
      workspace-switch.spring = {
        damping-ratio = 0.8;
        stiffness = 520;
        epsilon = 0.0001;
      };
      window-open = {
        duration-ms = 160;
        curve = "ease-out-expo";
      };
      window-close = {
        duration-ms = 140;
        curve = "ease-out-quad";
      };
      horizontal-view-movement.spring = {
        damping-ratio = 0.85;
        stiffness = 420;
        epsilon = 0.0001;
      };
      window-movement.spring = {
        damping-ratio = 0.75;
        stiffness = 320;
        epsilon = 0.0001;
      };
      window-resize.spring = {
        damping-ratio = 0.85;
        stiffness = 420;
        epsilon = 0.0001;
      };
      config-notification-open-close.spring = {
        damping-ratio = 0.65;
        stiffness = 900;
        epsilon = 0.001;
      };
      screenshot-ui-open = {
        duration-ms = 200;
        curve = "ease-out-quad";
      };
      overview-open-close.spring = {
        damping-ratio = 0.85;
        stiffness = 800;
        epsilon = 0.0001;
      };
    };
  };
}
