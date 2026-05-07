{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (builtins) attrValues;
  inherit (config.dot) machine;
in
{
  config = mkIf (machine.gpu == "intel" || machine.gpu == "hybrid-nv") {
    # we enable modesetting since this is recomeneded for intel gpus
    services.xserver.videoDrivers = [ "modesetting" ];

    # OpenCL support and VAAPI
    hardware.graphics = {
      extraPackages = attrValues {
        inherit (pkgs) libva-vdpau-driver intel-media-driver;

        intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
      };

      extraPackages32 = attrValues {
        inherit (pkgs.pkgsi686Linux) libva-vdpau-driver intel-media-driver;

        intel-vaapi-driver = pkgs.pkgsi686Linux.intel-vaapi-driver.override { enableHybridCodec = true; };
      };
    };

    # environment.systemPackages = [ pkgs.intel-gpu-tools ];
    #
    # environment.variables = mkIf (config.hardware.graphics.enable && machine.gpu != "hybrid-nv") {
    #   VDPAU_DRIVER = "va_gl";
    # };
  };
}
