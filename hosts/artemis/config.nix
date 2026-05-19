{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    (import ../common/disko/luks-btrfs-tmpfs.nix { })
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
      btrbk.enable = true;
      zram.enable = true;
      printing.enable = true;
      fwupd.enable = true;
    };

    virtual.enable = true;
    persistence.enable = true;

    machine = {
      type = "desktop";
      cpu = "amd";
      gpu = "nvidia";
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
