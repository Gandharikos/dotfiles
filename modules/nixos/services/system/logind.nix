{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  isLaptop = config.my.machine.type == "laptop";
in {
  config = mkIf isLaptop {
    services.logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandlePowerKey = "suspend-then-hibernate";
    };

    # https://wiki.debian.org/Suspend#Disable_suspend_and_hibernation
    systemd.sleep.settings.Sleep = mkIf (!config.my.gui.enable) {
      AllowSuspend = false;
      AllowHibernation = false;
      AllowSuspendThenHibernate = false;
      AllowHybridSleep = false;
    };
  };
}
