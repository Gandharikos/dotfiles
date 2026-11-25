# IPv4 LAN gateway. Flint retains DHCP; no guest/VLAN admission or IPv6 gateway.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  proxy = config.dot.networking.proxy;
  enabled = proxy.enable && proxy.backend == "sing-box";
  subnet = "192.168.8.0/24";
  lan = "enp2s0";
  tun = "sb-tun";
  clientMatch = ''iifname "${lan}" ip saddr ${subnet}'';
in
{
  config = lib.mkIf enabled {
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      # Single-arm routing must never redirect clients to Flint around this gateway.
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv4.conf.enp2s0.send_redirects" = 0;
    };
    systemd.network.networks."10-management" = {
      networkConfig.IPv4Forwarding = true;
      # Let the link owner recreate this rule after networkd reconfiguration.
      routingPolicyRules = [
        {
          From = subnet;
          To = "100.64.0.0/10";
          IncomingInterface = lan;
          Table = 2023;
          Priority = 5100;
        }
      ];
    };
    services.resolved.settings.Resolve.DNSStubListenerExtra = [ "192.168.8.2" ];

    networking.firewall = {
      extraInputRules = ''
        ${clientMatch} ip daddr 192.168.8.2 meta l4proto { tcp, udp } th dport 53 counter accept
      '';
      extraForwardRules = ''
        ${clientMatch} oifname "${tun}" counter accept
      '';
    };
    # Run before the normal established-connection accept rule. A lost TUN must not
    # send previously established LAN connections directly through Flint instead.
    # Keep the legacy table/unit names to preserve their existing lifecycle ownership.
    networking.nftables.tables.heimdall-pilot = {
      family = "inet";
      content = ''
        chain forward_guard {
          type filter hook forward priority -5; policy accept;
          iifname "${lan}" meta nfproto ipv6 counter drop
          ${clientMatch} oifname != "${tun}" counter drop
        }
      '';
    };

    # Only forwarded LAN traffic uses the embedded Tailnet identity. Host-local
    # management continues to use the native Tailscale rules and table 52.
    systemd.services.heimdall-pilot-tailnet = {
      description = "Route the IPv4 LAN's Tailnet traffic into sing-box";
      wantedBy = [ "sing-box.service" ];
      after = [ "sing-box.service" ];
      bindsTo = [ "sing-box.service" ];
      partOf = [ "sing-box.service" ];
      path = [
        pkgs.iproute2
        pkgs.gnugrep
        pkgs.coreutils
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = "40s";
      };
      script = ''
        set -eu
        for attempt in $(seq 1 30); do
          if ip -4 address show dev ${tun} 2>/dev/null | grep -q '172.19.0.1/30'; then
            break
          fi
          sleep 1
        done
        ip -4 address show dev ${tun} | grep -q '172.19.0.1/30'
        if [ -n "$(ip -4 route show table 2023 2>/dev/null || true)" ]; then
          echo 'Pilot routing table 2023 is already occupied' >&2
          exit 1
        fi
        ip -4 route add table 2023 100.64.0.0/10 via 172.19.0.2 dev ${tun}
      '';
      postStop = ''
        ip -4 route del table 2023 100.64.0.0/10 via 172.19.0.2 dev ${tun} 2>/dev/null || true
      '';
    };
  };
}
