{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe' getExe;
  inherit (lib.my) withUWSM withUWSM';
  inherit (config) gtk;
  cfg = config.my.gui.desktop.niri;

  bash = getExe pkgs.bash;
  gsettings = getExe' pkgs.glib "gsettings";
  gnomeSchema = "org.gnome.desktop.interface";
  wl-paste = withUWSM' pkgs pkgs.wl-clipboard "wl-paste";
  wl-clip-persist = withUWSM pkgs "wl-clip-persist";
  cliphist = getExe pkgs.cliphist;
  uwsmSpawn = command: [bash "-lc" command];
in {
  config = mkIf cfg.enable {
    programs.niri.settings.spawn-at-startup = [
      {command = [gsettings "set" gnomeSchema "gtk-theme" gtk.theme.name];}
      {command = [gsettings "set" gnomeSchema "icon-theme" gtk.iconTheme.name];}
      {command = [gsettings "set" gnomeSchema "cursor-theme" gtk.cursorTheme.name];}
      {command = [gsettings "set" gnomeSchema "gtk-font-theme" gtk.font.name];}
      {command = uwsmSpawn "${wl-clip-persist} --clipboard regular";}
      {command = uwsmSpawn "${wl-paste} --type text --watch ${cliphist} store";}
      {command = uwsmSpawn "${wl-paste} --type image --watch ${cliphist} store";}
    ];
  };
}
