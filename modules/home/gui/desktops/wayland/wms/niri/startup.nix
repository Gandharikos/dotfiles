{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe' getExe;
  inherit (config) gtk;
  cfg = config.my.desktop.niri;

  gsettings = getExe' pkgs.glib "gsettings";
  gnomeSchema = "org.gnome.desktop.interface";
  uwsm = getExe pkgs.uwsm;
  wl-paste = getExe' pkgs.wl-clipboard "wl-paste";
  wl-clip-persist = getExe pkgs.wl-clip-persist;
  cliphist = getExe pkgs.cliphist;

  uwsmCommand = program: args: [uwsm "app" "--" program] ++ args;
in {
  config = mkIf cfg.enable {
    programs.niri.settings.spawn-at-startup = [
      {command = [gsettings "set" gnomeSchema "gtk-theme" gtk.theme.name];}
      {command = [gsettings "set" gnomeSchema "icon-theme" gtk.iconTheme.name];}
      {command = [gsettings "set" gnomeSchema "cursor-theme" gtk.cursorTheme.name];}
      {command = [gsettings "set" gnomeSchema "gtk-font-theme" gtk.font.name];}
      {command = uwsmCommand wl-clip-persist ["--clipboard" "regular"];}
      {command = uwsmCommand wl-paste ["--type" "text" "--watch" cliphist "store"];}
      {command = uwsmCommand wl-paste ["--type" "image" "--watch" cliphist "store"];}
    ];
  };
}
