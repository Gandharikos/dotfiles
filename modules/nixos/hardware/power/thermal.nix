{
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.dot) device;
in
{
  config = mkIf (device.type == "laptop") {
    services = {
      # Intel-specific thermal management daemon
      # Note: thermald is Intel-only and doesn't work on AMD CPUs
      # AMD CPUs handle thermal management through ACPI and firmware automatically
      thermald.enable = device.cpu == "intel";
    };
  };
}
