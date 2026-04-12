{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./asus-dialpad.nix
    (import ../common/disko/luks-btrfs-tmpfs.nix { })
  ];

  my = {
    security.auditd.enable = lib.mkForce false;
    boot = {
      secureBoot = false;
      tmpOnTmpfs = false;
      enableKernelTweaks = true;
      # DISABLED: Potential conflict with NVIDIA/ASUS drivers
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
      # DISABLED: Potential conflict causing kernel panic
      # asus.enable = true;
      # samba.enable = true;
    };
    virtual.enable = true;
    persistence.enable = true;
    networking.enableIPv6 = false;
    machine = {
      type = "laptop";
      cpu = "amd";
      gpu = "nvidia";
      hasBluetooth = true;
      hasPrinter = false;
      hasTPM = true;
      # ethernetDevices = [ "wlp2s0" ]; # ymir wifi device
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
      backend = "kanata";
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
