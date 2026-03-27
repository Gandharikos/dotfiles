{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf mkDefault;
  isNvidia = config.my.machine.gpu == "nvidia";
in
{
  config = mkIf isNvidia {

    services.xserver.videoDrivers = [ "nvidia" ];

    boot = {
      blacklistedKernelModules = [ "snd_hda_codec_hdmi" ];

      # Enable the Nvidia's experimental framebuffer device
      # fix for the imaginary monitor taht does not exist
      kernelModules = [ "nvidia_drm.fbdev=1" ];
    };

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "nvidia";

      # GBM_BACKEND = "nvidia-drm"; # breaks firefox apparently
      WLR_DRM_DEVICES = mkDefault "/dev/dri/card1";
    };

    environment.systemPackages = with pkgs; [
      # vulkan
      vulkan-tools
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer

      # libva
      libva
      libva-utils
    ];

    hardware = {
      nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.beta;

        powerManagement = {
          enable = true;
          finegrained = false;
        };

        open = false; # don't use the open drivers by default
        nvidiaSettings = false; # adds nvidia-settings to pkgs, so useless on nixos
        nvidiaPersistenced = true;
      };

      graphics = {
        extraPackages = [ pkgs.nvidia-vaapi-driver ];
        extraPackages32 = [ pkgs.pkgsi686Linux.nvidia-vaapi-driver ];
      };
    };
  };
}
