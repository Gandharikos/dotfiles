{lib, ...}: {
  imports = [
    ./hardware-configuration.nix
    (import ../common/disko/luks-btrfs-tmpfs.nix {})
  ];

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
    btrbk.enable = true;
    zram.enable = true;
    services = {
      printing.enable = true;
      # samba.enable = true;
    };
    virtual.enable = true;
    persistence.enable = true;
    networking.enableIPv6 = false;
    machine = {
      type = "laptop";
      cpu = "intel";
      gpu = "intel";
      hasSound = true;
      hasBluetooth = true;
      hasPrinter = false;
      hasTPM = true;
      monitors = [
        {
          name = "eDP-1";
          resolution = "preferred";
          position = "auto";
          scale = 2.0;
        }
      ];
    };
    keyboard = {
      layout = "qwerty";
      kanata.enable = true;
    };
  };

  # for surge
  networking = {
    nameservers = lib. mkForce [
      "198.18.0.2"
    ];
    tcpcrypt.enable = lib.mkForce false;
  };

  hm.my = {
    browser.default = "google-chrome";
    terminal.size = 12;
    desktop.apps = {
      chrome.enable = true;
      firefox.enable = lib.mkForce false;
      zen.enable = lib.mkForce false;
    };
  };
}
