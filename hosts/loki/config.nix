{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    (import ../common/disko/luks-btrfs-tmpfs.nix { })
  ];

  dot = {
    primaryUser = "johnson";
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
    networking.enableIPv6 = false;
    device = {
      type = "laptop";
      cpu = "intel";
      gpu = "intel";
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
      backend = "kanata";
    };
  };

  nixporn.colorscheme = "catppuccin";

  # for surge
  time = {
    timeZone = lib.mkForce "Asia/Shanghai";
    hardwareClockInLocalTime = lib.mkForce false;
  };

  services.automatic-timezoned.enable = lib.mkForce false;
}
