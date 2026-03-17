{
  config,
  lib,
  ...
}:
let
  inherit (config.my) machine;
  inherit (lib.modules) mkIf;
in
{
  config = mkIf (machine.cpu == "amd" || machine.cpu == "vm-amd") {
    hardware.cpu.amd.updateMicrocode = true;
    boot.kernelModules = [
      "kvm-amd"
      "amd-pstate"
    ];
  };
}
