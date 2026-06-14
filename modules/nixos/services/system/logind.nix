{
  lib,
  config,
  ...
}:
let
  inherit (lib.options) mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) enum;
  isLaptop = config.dot.device.type == "laptop";
  cfg = config.dot.services.logind;
  lidActions = [
    "ignore"
    "poweroff"
    "reboot"
    "halt"
    "kexec"
    "suspend"
    "hibernate"
    "hybrid-sleep"
    "suspend-then-hibernate"
    "lock"
  ];
in
{
  options.dot.services.logind = {
    lidSwitch = mkOption {
      type = enum lidActions;
      default = "suspend";
      description = "Action to take when the laptop lid is closed.";
    };

    lidSwitchDocked = mkOption {
      type = enum lidActions;
      default = "ignore";
      description = "Action to take when the lid is closed while docked.";
    };

    lidSwitchExternalPower = mkOption {
      type = enum lidActions;
      default = "suspend";
      description = "Action to take when the lid is closed on external power.";
    };

    powerKey = mkOption {
      type = enum lidActions;
      default = "suspend-then-hibernate";
      description = "Action to take when the power key is pressed.";
    };
  };

  config = mkIf isLaptop {
    services.logind.settings.Login = {
      HandleLidSwitch = cfg.lidSwitch;
      HandleLidSwitchDocked = cfg.lidSwitchDocked;
      HandleLidSwitchExternalPower = cfg.lidSwitchExternalPower;
      HandlePowerKey = cfg.powerKey;
    };

    # https://wiki.debian.org/Suspend#Disable_suspend_and_hibernation
    systemd.sleep.settings.Sleep = mkIf (!config.dot.gui.enable) {
      AllowSuspend = false;
      AllowHibernation = false;
      AllowSuspendThenHibernate = false;
      AllowHybridSleep = false;
    };
  };
}
