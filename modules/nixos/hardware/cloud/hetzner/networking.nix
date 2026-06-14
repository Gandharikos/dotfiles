{ config, lib, ... }:
let
  inherit (lib.modules) mkForce mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types) str;
  inherit (lib.strings) optionalString;
  cfg = config.dot.profiles.hetzner;
in
{
  options.dot.profiles.hetzner = {
    interface = mkOption {
      type = str;
      default = "eth0";
      description = "Hetzner Cloud network interface.";
    };
    ipv4 = mkOption {
      type = str;
      description = "IPv4 address assigned to the server.";
    };
    ipv6 = mkOption {
      type = str;
      description = "IPv6 address assigned to the server.";
    };
  };

  config = mkIf cfg.enable {
    dot.device.ethernetDevices = mkForce [ ];

    networking = {
      dhcpcd.enable = mkForce false;
      timeServers = [
        "ntp1.hetzner.de"
        "ntp2.hetzner.com"
        "ntp3.hetzner.net"
      ];
      usePredictableInterfaceNames = mkForce false;
    };

    systemd.network.networks.${cfg.interface} = {
      matchConfig.Name = cfg.interface;
      address = [
        "${cfg.ipv4}/32"
        "${cfg.ipv6}/64"
      ];
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = false;
      };
      routes = [
        {
          Destination = "172.31.1.1/32";
          Scope = "link";
        }
        {
          Gateway = "172.31.1.1";
          GatewayOnLink = true;
        }
        {
          Destination = "fe80::1/128";
        }
        {
          Gateway = "fe80::1";
          GatewayOnLink = true;
        }
      ];
    };

    services.udev.extraRules = optionalString (cfg.macAddress != null) ''
      ATTR{address}=="${cfg.macAddress}", NAME="${cfg.interface}"
    '';
  };
}
