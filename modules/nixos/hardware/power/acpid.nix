{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.dot) device;
in
{
  config = mkIf (device.type == "laptop") {
    # handle ACPI events
    services.acpid.enable = true;

    environment.systemPackages = with pkgs; [
      acpi
      powertop
    ];

    boot = {
      kernelModules = [ "acpi_call" ];
      extraModulePackages = with config.boot.kernelPackages; [
        acpi_call
        cpupower
      ];
    };
  };
}
