{
  lib,
  pkgs,
  config,
  ...
}:
let
  isAmd = config.dot.device.gpu == "amd";
  inherit (lib.modules) mkIf;
in
{
  config = mkIf isAmd {
    # enable amdgpu xorg drivers
    services.xserver.videoDrivers = [ "amdgpu" ];

    # enable amdgpu kernel module
    boot.kernelModules = [ "amdgpu" ];

    # enables AMDVLK & OpenCL support
    hardware.graphics.extraPackages = with pkgs.rockPackages; [
      clr
      clr.icd
    ];
  };
}
