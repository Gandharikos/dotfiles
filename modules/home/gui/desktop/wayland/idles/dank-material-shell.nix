{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.my.gui) desktop;

  idleCfg = desktop.idle;
  enable =
    desktop.wayland.enable
    && idleCfg.default == "dank-material-shell"
    && (config.programs.dank-material-shell.enable or false);
  monitorTimeout = lib.max 0 (idleCfg.timeout - 10);
in
{
  config = mkIf enable {
    programs.dank-material-shell.session = {
      acMonitorTimeout = monitorTimeout;
      acLockTimeout = idleCfg.timeout;
      acSuspendTimeout = idleCfg.timeout + 10;

      batteryMonitorTimeout = monitorTimeout;
      batteryLockTimeout = idleCfg.timeout;
      batterySuspendTimeout = idleCfg.timeout + 10;
    };
  };
}
