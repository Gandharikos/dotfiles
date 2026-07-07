{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    (import ../common/disko/luks-btrfs-tmpfs.nix { })
  ];

  dot = {
    primaryUser = "johnson";
    kernel.tweaks.enable = false;
    boot = {
      secureBoot = false;
      tmpOnTmpfs = false;
      plymouth.enable = false;

      initrd = {
        tweaks.enable = true;
        optimizeCompressor = true;
      };
    };
    gui.game.enable = true;
    security.enable = true;
    services = {
      btrbk.enable = true;
      zram.enable = true;
      printing.enable = true;
      fwupd.enable = true;
    };
    virtual.enable = true;
    persistence.enable = true;
    device = {
      type = "desktop";
      cpu = "intel";
      gpu = "nvidia";
      hasBluetooth = true;
      hasPrinter = false;
      hasTPM = true;
    };
  };
}
