{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe getExe';
  inherit (lib.dot) uwsmApp withUWSM withUWSM';
  inherit (config) gtk;
  gsettings = getExe' pkgs.glib "gsettings";
  gnomeSchema = "org.gnome.desktop.interface";
  cfg = config.my.gui.desktop.hyprland;
  wl-paste' = withUWSM' pkgs pkgs.wl-clipboard "wl-paste";
  wl-clip-persist' = withUWSM pkgs "wl-clip-persist";
  cliphist' = getExe pkgs.cliphist;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      exec = [
        "${uwsmApp pkgs gsettings [
          "set"
          gnomeSchema
          "gtk-theme"
          gtk.theme.name
        ]}"
        "${uwsmApp pkgs gsettings [
          "set"
          gnomeSchema
          "icon-theme"
          gtk.iconTheme.name
        ]}"
        "${uwsmApp pkgs gsettings [
          "set"
          gnomeSchema
          "cursor-theme"
          gtk.cursorTheme.name
        ]}"
        "${uwsmApp pkgs gsettings [
          "set"
          gnomeSchema
          "gtk-font-theme"
          gtk.font.name
        ]}"
      ];

      exec-once = [
        "${wl-clip-persist'} --clipboard regular"
        "${wl-paste'} --type text --watch ${cliphist'} store"
        "${wl-paste'} --type image --watch ${cliphist'} store"
      ];
    };
  };
}
