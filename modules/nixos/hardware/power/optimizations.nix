{
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.my) machine;
in
{
  config = mkIf (machine.type == "laptop") {

    # Additional kernel parameters for power saving
    boot.kernelParams = [
      # Enable SATA link power management (aggressive)
      "ahci.mobile_lpm_policy=3"
      # Disable NMI watchdog to save CPU cycles
      "nmi_watchdog=0"
    ];

    # Note: CPU-specific power management is handled in:
    # - Intel: hardware/power/thermal.nix (thermald)
    # - AMD: hardware/cpu/amd.nix (amd-pstate module)

    # System-level power optimizations
    powerManagement = {
      enable = true;
      powertop.enable = true; # Auto-tune power settings on boot
      cpuFreqGovernor = lib.mkDefault "powersave";
    };
  };
}
