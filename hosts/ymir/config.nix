{inputs, ...}: {
  imports = [
    inputs.hardware.nixosModules.dell-xps-15-9560-nvidia
    (import ../common/disko/luks-btrfs-tmpfs.nix {
      device = "/dev/nvme0n1";
      swapSize = "8G";
    })
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  # networking.interfaces.eno2.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlo1.useDHCP = lib.mkDefault true;

  my = {
    boot = {
      secureBoot = false;
      tmpOnTmpfs = false;
      enableKernelTweaks = true;
      # TODO: diable for debugging
      plymouth.enable = false;

      initrd = {
        enableTweaks = true;
        optimizeCompressor = true;
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
    security.enable = false;
    services = {
      btrbk.enable = true;
      zram.enable = true;
      printing.enable = true;
      fwupd.enable = true;
      # samba.enable = true;
    };
    virtual.enable = true;
    persistence.enable = true;
    machine = {
      type = "laptop";
      cpu = "intel";
      gpu = "nvidia";
      hasSound = true;
      hasBluetooth = true;
      hasPrinter = false;
      hasTPM = true;
      ethernetDevices = ["wlp2s0"]; # ymir wifi device
    };
  };
}
