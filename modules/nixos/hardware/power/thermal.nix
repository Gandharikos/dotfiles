{
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.dot) machine;
in
{
  config = mkIf (machine.type == "laptop") {
    services = {
      # Intel-specific thermal management daemon
      # Note: thermald is Intel-only and doesn't work on AMD CPUs
      # AMD CPUs handle thermal management through ACPI and firmware automatically
      thermald.enable = machine.cpu == "intel";
    };
  };
}
