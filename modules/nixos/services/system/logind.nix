{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (config.my) desktop;
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
    systemd.sleep.extraConfig = mkIf desktop.enable ''
      AllowSuspend=no
      AllowHibernation=no
      AllowSuspendThenHibernate=no
      AllowHybridSleep=no
    '';
  };
}
