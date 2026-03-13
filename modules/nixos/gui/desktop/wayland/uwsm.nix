{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe;
  inherit (config.my.gui) desktop;
  sessionName = "${desktop.default}-uwsm";
  uwsm' = getExe pkgs.uwsm;
in {
  config = mkIf desktop.uwsm.enable {
    programs.uwsm.enable = true;
    services.displayManager.defaultSession = sessionName;
    my.gui.desktop.exec = "${uwsm'} start ${sessionName}.desktop";
  };
}
