{ lib, ... }:
{
  imports = [
    (import ../common/disko/bios-ext4.nix {
      device = "/dev/sda";
      swapSize = "2G";
    })
  ];

  networking.domain = "huwenqiang.dev";

  dot = {
    primaryUser = "johnson";
    users.johnson.home.my.direnv.enable = lib.mkForce false;

    boot = {
      enableKernelTweaks = true;
      initrd = {
        enableTweaks = true;
        optimizeCompressor = false;
      };
    };

    profiles.hetzner = {
      enable = true;
      ipv4 = "159.69.182.58";
      ipv6 = "2a01:4f8:c015:cfa3::1";
    };

    networking = {
      enableIPv6 = true;
      tailscale = {
        enable = true;
        autoConnect = true;
        role = "client";
        acceptRoutes = false;
        acceptDns = false;
      };
      vpn.enable = false;
    };

    yubikey.enable = false;
    persistence.enable = false;
    users.johnson.home.my = {
      atuin.enable = lib.mkForce false;
      git.enable = lib.mkForce false;
      mail.enable = lib.mkForce false;
      mcp.enable = lib.mkForce false;
      neovim.distro = lib.mkForce null;
      polymarket.enable = lib.mkForce false;
    };
    selfhosted = {
      enable = true;
      domain = "huwenqiang.dev";
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
