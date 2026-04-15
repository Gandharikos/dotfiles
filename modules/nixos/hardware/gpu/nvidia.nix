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
      # Enables the Nvidia's experimental framebuffer device
      # fix for the imaginary monitor that does not exist
      kernelParams = [ "nvidia_drm.fbdev=1" ];

      blacklistedKernelModules = [ "snd_hda_codec_hdmi" ];
    };

    environment = {
      sessionVariables = {
        LIBVA_DRIVER_NAME = "nvidia";

        # GBM_BACKEND = "nvidia-drm"; # breaks firefox apparently
        WLR_DRM_DEVICES = mkDefault "/dev/dri/card1";
      };

      systemPackages = with pkgs; [
        # vulkan
        vulkan-tools
        vulkan-loader
        vulkan-validation-layers
        vulkan-extension-layer

        # libva
        libva
        libva-utils
      ];
    };

    hardware = {
      nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.beta;

        powerManagement = {
          enable = true;
          # Disable fine-grained PM - let NVIDIA run like on Windows
          finegrained = false;
        };

        open = false;
        nvidiaSettings = false;
        nvidiaPersistenced = true; # Enable for always-on mode
      };

      graphics = {
        extraPackages = with pkgs; [ nvidia-vaapi-driver ];
        extraPackages32 = with pkgs.pkgsi686Linux; [ nvidia-vaapi-driver ];
      };
    };
  };
}
