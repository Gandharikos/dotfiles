{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./maintenance.nix
    ./sing-box.nix
    (import ../common/disko/ext4.nix {
      device = "/dev/disk/by-id/nvme-CWDISK_128GB_SSD_LST95128B23QL00639";
      swapSize = null;
    })
  ];

  systemd.network = {
    networks."10-management" = {
      matchConfig.PermanentMACAddress = "a8:b8:e0:06:d6:97";
      addresses = [
        {
          Address = "192.168.8.2/24";
          DuplicateAddressDetection = "ipv4";
        }
      ];
      routes = [ { Gateway = "192.168.8.1"; } ];
      networkConfig = {
        DHCP = "no";
        DNS = [ "192.168.8.1" ];
        IPv6AcceptRA = false;
        LinkLocalAddressing = "no";
        IPv4Forwarding = false;
        IPv6Forwarding = false;
        DHCPServer = false;
        LLDP = false;
        EmitLLDP = false;
      };
    };
  };
  boot.loader.efi.canTouchEfiVariables = true;
  dot = {
    primaryUser = "johnson";
    stateVersion = "26.11";
    device = {
      type = "server";
      cpu = "intel";
      ethernetDevices = [ ];
    };
    profiles.router.enable = true;
    boot = {
      loader = "systemd-boot";
      secureBoot = false;
    };
    networking = {
      enableIPv6 = false;
      tailscale = {
        enable = true;
        autoConnect = true;
        role = "client";
        acceptRoutes = false;
        acceptDns = false;
        # Clear any saved exit-node selection; use the host's own default route.
        # Unlike null (unmanaged), "" explicitly disables using another node as an exit.
        # This does not control whether this host advertises itself as an exit node.
        exitNode = "";
      };
    };
    users.johnson = {
      initialHashedPassword = lib.mkForce "!";
      home.my = {
        langs.enable = lib.mkForce false;
        git.enable = lib.mkForce false;
        neovim.enable = lib.mkForce false;
        direnv.enable = lib.mkForce false;
        atuin.enable = lib.mkForce false;
      };
    };
  };
}
