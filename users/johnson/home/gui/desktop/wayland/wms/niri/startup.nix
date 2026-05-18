{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe;
  inherit (lib.dot) withUWSMArgs withUWSMArgs';
  cfg = config.my.gui.desktop.niri;

  wl-paste = withUWSMArgs' pkgs pkgs.wl-clipboard "wl-paste";
  wl-clip-persist = withUWSMArgs pkgs "wl-clip-persist";
  cliphist = getExe pkgs.cliphist;
in
{
  config = mkIf cfg.enable {
    programs.niri.settings.spawn-at-startup = [
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
