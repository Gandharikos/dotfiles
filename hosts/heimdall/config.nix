{ lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./maintenance.nix
    ./sing-box.nix
    ./gateway.nix
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
        IPv4Forwarding = true;
        IPv6Forwarding = false;
        DHCPServer = false;
        LLDP = false;
        EmitLLDP = false;
      };
    };
  };
  # Ordinary native exit routing is independent of the LAN proxy pilot.
  services.tailscale.useRoutingFeatures = "both";
  boot.kernel.sysctl = {
    # The native exit owns this even when the optional LAN pilot is disabled.
    "net.ipv4.ip_forward" = lib.mkForce 1;
    "net.ipv6.conf.default.forwarding" = 1;
    "net.ipv6.conf.enp2s0.forwarding" = 0;
  };
  # NixOS filters forwarding here; retain Internet-only access rather than trusting
  # the whole Tailnet interface or exposing the home LAN as a subnet route.
  networking.firewall.extraForwardRules = ''
    iifname "tailscale0" oifname "enp2s0" ip saddr 100.64.0.0/10 ip daddr != { 0.0.0.0/8, 10.0.0.0/8, 100.64.0.0/10, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16, 224.0.0.0/4, 240.0.0.0/4 } counter accept
  '';
  # ExitDNS reads /etc/resolv.conf. Give only tailscaled a real-IP resolver;
  # host/LAN DNS must retain the existing sing-box Fake-IP path.
  systemd.services.tailscaled.serviceConfig.BindReadOnlyPaths = [
    "${pkgs.writeText "heimdall-tailscale-resolv.conf" ''
      nameserver 192.168.8.1
      options timeout:2 attempts:2
    ''}:/etc/resolv.conf"
  ];

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
        role = "exit-node";
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
