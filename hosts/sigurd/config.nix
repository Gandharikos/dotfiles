{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    (import ../common/disko/luks-btrfs-tmpfs.nix {})
  ];

  my = {
    boot = {
      secureBoot = false;
      tmpOnTmpfs = false;
      enableKernelTweaks = false;
      plymouth.enable = false;

      initrd = {
        enableTweaks = false;
        optimizeCompressor = false;
      };

      fs = [
        "ext4"
        "btrfs"
        "xfs"
        "ntfs"
        "fat"
        "vfat"
        "exfat"
      ];
    };
    video.enable = true;
    btrbk.enable = true;
    zram.enable = true;
    game.enable = true;
    security.enable = true;
    services = {
      printing.enable = true;
    };
    virtual.enable = true;
    persistence.enable = true;
    machine = {
      type = "desktop";
      cpu = "intel";
      gpu = "nvidia";
      hasSound = true;
      hasBluetooth = true;
      hasPrinter = false;
      hasTPM = true;
    };
  };
}
