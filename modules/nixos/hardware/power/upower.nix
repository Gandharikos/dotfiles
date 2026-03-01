{
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (config.my) machine;
in {
  config = mkIf (machine.type == "laptop") {
    # DBus service that provides power management support to applications.
    services.upower = {
      enable = true;
      percentageLow = 15;
      percentageCritical = 5;
      percentageAction = 3;
      criticalPowerAction = "Hibernate";
    };
  };
}
