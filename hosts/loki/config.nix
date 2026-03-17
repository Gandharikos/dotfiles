{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    (import ../common/disko/luks-btrfs-tmpfs.nix { })
  ];

  my = {
    boot = {
      secureBoot = false;
      tmpOnTmpfs = false;
      enableKernelTweaks = true;
      plymouth.enable = true;

      initrd = {
        enableTweaks = true;
        optimizeCompressor = true;
      };
    };
    video.enable = true;
    services = {
      btrbk.enable = true;
      zram.enable = true;
      printing.enable = true;
      fwupd.enable = true;
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
  time = {
    timeZone = lib.mkForce "Asia/Shanghai";
    hardwareClockInLocalTime = lib.mkForce false;
  };

  services.automatic-timezoned.enable = lib.mkForce false;

  networking = {
    nameservers = lib.mkForce [
      "198.18.0.2"
    ];
    tcpcrypt.enable = lib.mkForce false;
  };

  hm.my = {
    gui.browser.default = "google-chrome";
    gui.terminal.size = 12;
    gui.apps = {
      chrome.enable = true;
      firefox.enable = lib.mkForce false;
      zen.enable = lib.mkForce false;
    };
  };
}
