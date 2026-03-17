{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf mkMerge mkDefault;
  isNvidia = config.my.machine.gpu == "nvidia";
  isHybrid = config.my.machine.gpu == "hybrid-nv";
  waylandEnabled = config.my.gui.desktop.wayland.enable;
in
{
  config = mkIf isNvidia {
    # nvidia drivers kinda are unfree software
    nixpkgs.config.allowUnfree = true;

    services.xserver = mkMerge [
      { videoDrivers = [ "nvidia" ]; }

      # xorg settings
      (mkIf (!waylandEnabled) {
        # disable DPMS
        monitorSection = ''
          Option "DPMS" "false"
        '';

        # disable screen blanking in general
        serverFlagsSection = ''
          Option "StandbyTime" "0"
          Option "SuspendTime" "0"
          Option "OffTime" "0"
          Option "BlankTime" "0"
        '';
      })
    ];

    boot = {
      # blacklist mouveau module as otherwise it conflicts with nvidia drm
      blacklistedKernelModules = [ "nouveau" ];

      # Enable the Nvidia's experimental framebuffer device
      # fix for the imaginary monitor taht does not exist
      kernelModules = [ "nvidia_drm.fbdev=1" ];
    };

    environment.sessionVariables = mkMerge [
      { LIBVA_DRIVER_NAME = "nvidia"; }
      (mkIf waylandEnabled {
        WLR_DRM_DEVICES = mkDefault "/dev/dri/card1";
        LIBVA_DRIVER_NAME = "nvidia";
        WLR_NO_HARDWARE_CURSORS = "1";

        # May cause Firefox crashes
        GBM_BACKEND = "nvidia-drm";

        # If you face problems with Discord windows not displaying or screen
        # sharing not working in Zoom, remove or comment this:
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      })
    ];

    environment.systemPackages = with pkgs; [
      # mesa
      mesa

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
        package = mkDefault config.boot.kernelPackages.nvidiaPackages.beta;

        prime.offload = {
          enable = isHybrid;
          enableOffloadCmd = isHybrid;
        };

        powerManagement = {
          enable = mkDefault true;
          finegrained = mkDefault false;
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
