{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.my) machine;
in
{
  config = mkIf (machine.cpu == "intel" || machine.cpu == "vm-intel") {
    hardware.cpu.intel.updateMicrocode = true;

    boot = {
      kernelModules = [ "kvm-intel" ];
      kernelParams = [
        "i915.fastboot=1"
        "enable_gvt=1"
      ];
    };
  };
}
