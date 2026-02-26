{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.my.desktop.niri;
in {
  config = mkIf cfg.enable {
    programs.niri.settings.environment = {
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "niri";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_QPA_PLATFORMTHEME = "qt6ct";
      SDL_VIDEODRIVER = "wayland";
      _JAVA_AWT_WM_NONEREPARENTING = "1";
      CLUTTER_BACKEND = "wayland";
      GDK_BACKEND = "wayland,x11";
      GDK_DPI_SCALE = "1";
      GDK_SCALE = "1";
      NIXOS_OZONE_WL = "1";
    };
  };
}
