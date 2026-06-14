{ lib, ... }:
{
  imports = [
    (import ../common/disko/bios-ext4.nix {
      device = "/dev/sda";
      swapSize = "2G";
    })
  ];

  boot.loader = {
    efi.canTouchEfiVariables = lib.mkForce false;
    grub = {
      dedsec-theme.enable = lib.mkForce false;
    };
  };

  networking.domain = "huwenqiang.dev";

  dot = {
    primaryUser = "johnson";

    boot = {
      loader = "grub";
      secureBoot = false;
      tmpOnTmpfs = false;
      enableKernelTweaks = true;
      plymouth.enable = false;

      initrd = {
        enableTweaks = true;
        optimizeCompressor = false;
      };
    };

    device = {
      type = "server";
    };

    profiles.hetzner = {
      enable = true;
      ipv4 = "159.69.182.58";
      ipv6 = "2a01:4f8:c015:cfa3::1";
    };

    networking.enableIPv6 = true;

    persistence.enable = false;
    selfhosted = {
      enable = true;
      domainSuffix = "huwenqiang.dev";
      reverseProxy = "caddy";
      monitoring = "gatus";
      backup = "restic";
    };

    services = {
      btrbk.enable = false;
      zram.enable = true;
    };
  };
}
