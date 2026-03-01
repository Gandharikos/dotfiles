{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (config.my) machine;
in {
  config = mkIf (machine.type == "laptop") {
    # pretty much handled by brightnessctl
    hardware.acpilight.enable = false;

    # handle ACPI events
    services.acpid.enable = true;

    environment.systemPackages = with pkgs; [
      acpi
      powertop
    ];

    boot = {
      kernelModules = ["acpi_call"];
      extraModulePackages = with config.boot.kernelPackages; [
        acpi_call
        cpupower
      ];
    };
  };
}
