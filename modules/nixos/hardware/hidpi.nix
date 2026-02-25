{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (config.my.machine) hasHidpi;
  inherit (lib.my) isWayland;
in {
  config = mkIf hasHidpi {
    environment.sessionVariables =
      if isWayland config
      then {
        # Wayland: Rely on compositor-led scaling, enable auto-detection
        QT_AUTO_SCREEN_SCALE_FACTOR = "1";
        QT_ENABLE_HIGHDPI_SCALING = "1";
        QT_QPA_PLATFORM = "wayland;xcb";
      }
      else {
        # X11/Xorg: Forced scaling factors
        QT_DEVICE_PIXEL_RATIO = "2";
        QT_SCALE_FACTOR = "2";
        QT_ENABLE_HIGHDPI_SCALING = "1";
        QT_AUTO_SCREEN_SCALE_FACTOR = "1";
        GDK_SCALE = "2";
        GDK_DPI_SCALE = "0.5";
      };
  };
}
