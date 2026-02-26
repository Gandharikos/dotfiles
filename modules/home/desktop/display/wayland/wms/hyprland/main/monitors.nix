{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.lists) optionals;
  inherit (lib.strings) concatStringsSep;
  inherit (config.my.machine) monitors;
  cfg = config.my.desktop.hyprland;
  mkMonitors = ms:
    builtins.map (
      m: let
        sc = toString m.scale;
      in
        concatStringsSep "," [m.name m.resolution m.position sc]
    )
    ms;
  monitorsCfg = mkMonitors monitors;
  hasMonitor = builtins.length monitors > 0;
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      monitor =
        [",preferred,auto,1"]
        ++ (optionals hasMonitor monitorsCfg);
    };
  };
}
