{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe;
  inherit (lib.dot) withUWSM withUWSM';
  cfg = config.my.gui.desktop.hyprland;
  wl-paste' = withUWSM' pkgs pkgs.wl-clipboard "wl-paste";
  wl-clip-persist' = withUWSM pkgs "wl-clip-persist";
  cliphist' = getExe pkgs.cliphist;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      exec-once = [
        "${wl-clip-persist'} --clipboard regular"
        "${wl-paste'} --type text --watch ${cliphist'} store"
        "${wl-paste'} --type image --watch ${cliphist'} store"
      ];
    };
  };
}
