{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe' getExe;
  inherit (lib.dot) uwsmAppArgs withUWSMArgs withUWSMArgs';
  inherit (config) gtk;
  cfg = config.dot.gui.desktop.niri;

  gsettings = getExe' pkgs.glib "gsettings";
  gnomeSchema = "org.gnome.desktop.interface";
  wl-paste = withUWSMArgs' pkgs pkgs.wl-clipboard "wl-paste";
  wl-clip-persist = withUWSMArgs pkgs "wl-clip-persist";
  cliphist = getExe pkgs.cliphist;
in
{
  config = mkIf cfg.enable {
    programs.niri.settings.spawn-at-startup = [
      {
        command = uwsmAppArgs pkgs gsettings [
          "set"
          gnomeSchema
          "gtk-theme"
          gtk.theme.name
        ];
      }
      {
        command = uwsmAppArgs pkgs gsettings [
          "set"
          gnomeSchema
          "icon-theme"
          gtk.iconTheme.name
        ];
      }
      {
        command = uwsmAppArgs pkgs gsettings [
          "set"
          gnomeSchema
          "cursor-theme"
          gtk.cursorTheme.name
        ];
      }
      {
        command = uwsmAppArgs pkgs gsettings [
          "set"
          gnomeSchema
          "gtk-font-theme"
          gtk.font.name
        ];
      }
      {
        command = wl-clip-persist ++ [
          "--clipboard"
          "regular"
        ];
      }
      {
        command = wl-paste ++ [
          "--type"
          "text"
          "--watch"
          cliphist
          "store"
        ];
      }
      {
        command = wl-paste ++ [
          "--type"
          "image"
          "--watch"
          cliphist
          "store"
        ];
      }
    ];
  };
}
