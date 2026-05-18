{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    (import ../common/disko/ext4.nix { })
  ];

  dot = {
    primaryUser = "michael";

    users.johnson.enable = true;

    boot = {
      secureBoot = false;
      tmpOnTmpfs = false;
      enableKernelTweaks = true;
      plymouth.enable = false;

      initrd = {
        enableTweaks = true;
        optimizeCompressor = true;
      };
    };

    services = {
      btrbk.enable = false;
      zram.enable = true;
      printing.enable = true;
      fwupd.enable = true;
    };

    virtual.enable = true;
    persistence.enable = false;
    networking.enableIPv6 = true;

    machine = {
      type = "desktop";
      cpu = "amd";
      gpu = "intel";
      hasBluetooth = true;
      hasPrinter = false;
      hasTPM = true;
      monitors = [
        {
          name = "HDMI-A-1";
          resolution = "1920x1080@120";
          position = "auto";
          scale = 1.0;
        }
      ];
    };

    keyboard = {
      layout = "qwerty";
      backend = null;
    };
  };
}
