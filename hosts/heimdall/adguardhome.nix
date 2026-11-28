# LAN/host filtering precedes sing-box Fake-IP; native ExitDNS remains separate.
{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  proxy = config.dot.networking.proxy;
  enabled = proxy.enable && proxy.backend == "sing-box";
  variant = "fakenews-gambling-porn-social";
  seed = pkgs.fetchurl {
    name = "stevenblack-${variant}-hosts";
    url = "https://raw.githubusercontent.com/StevenBlack/hosts/81f6c19b6ae322732879d119e5cbdd8f8bf6c52c/alternates/${variant}/hosts";
    hash = "sha256-fqIR5QtoSRAIE/LzFu3fpWisJMy0eX2IT/KUYtb24DU=";
  };
  chineseSeed = pkgs.fetchurl {
    name = "anti-ad-easylist.txt";
    url = "https://raw.githubusercontent.com/privacy-protection-tools/anti-AD/25025b31a086b7d1c6226795966aaf2f9251430c/anti-ad-easylist.txt";
    hash = "sha256-qE8F4QSt2mFw2+77QJX5JlcSCAoDHEtXz2v41IpWRSY=";
  };
  tailscale = lib.getExe config.services.tailscale.package;
in
{
  config = lib.mkIf enabled {
    dot.networking.adguardhome = {
      enable = true;
      usersFile = config.sops.secrets.adguardhome_users.path;
      seedFiles = {
        "4" = seed;
        "3" = chineseSeed;
      };
    };
    # Override the shared profile's forced direct-to-core DNS, only on this host.
    services.resolved.settings.Resolve = {
      DNS = lib.mkOverride 40 [ "127.0.0.1" ];
      DNSStubListenerExtra = lib.mkForce [ ];
    };
    sops.secrets = {
      adguardhome_users = {
        sopsFile = "${self}/secrets/services/adguardhome.yaml";
        key = "users";
        restartUnits = [ "adguardhome.service" ];
      };
      # Root-only recovery copy for the operator; never consumed by the web service.
      adguardhome_admin_password = {
        sopsFile = "${self}/secrets/services/adguardhome.yaml";
        key = "admin_password";
      };
    };
    services.adguardhome = {
      settings = {
        http.address = "127.0.0.1:3000";
        dns = {
          bind_hosts = [
            "127.0.0.1"
            "192.168.8.2"
          ];
          port = 53;
          allowed_clients = [
            "127.0.0.0/8"
            "192.168.8.0/24"
          ];
          upstream_dns = [ "127.0.0.1:${toString proxy.profile.ports.dns}" ];
          bootstrap_dns = [ "192.168.8.1" ];
          # Do not export this gateway's loopback /etc/hosts entries to LAN clients.
          hostsfile_enabled = false;
          # sing-box owns the mapping/cache lifetime of its Fake-IP responses.
          cache_enabled = false;
          cache_size = 0;
          ratelimit = 0;
        };
        filtering = {
          rewrites_enabled = true;
          rewrites = [
            {
              domain = "heimdall";
              answer = "192.168.8.2";
              enabled = true;
            }
          ];
        };
        filters = [
          {
            # ID 2's cached variant lacks social domains.
            id = 4;
            enabled = true;
            name = "StevenBlack ads, tracking, fakenews, gambling, porn and social";
            url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/${variant}/hosts";
          }
          {
            id = 3;
            enabled = true;
            name = "anti-AD Chinese ads and tracking (DNS)";
            url = "https://anti-ad.net/easylist.txt";
          }
        ];
      };
    };
    systemd.services.adguardhome = {
      after = [
        "systemd-networkd.service"
        "systemd-resolved.service"
        "sing-box.service"
        "sops-install-secrets.service"
      ];
      wants = [
        "systemd-networkd.service"
        "sing-box.service"
      ];
      requires = [ "sops-install-secrets.service" ];
      # Global wait-online is disabled. Wait only for this host's static LAN IPv4
      # (including networkd's address configuration/DAD), not DNS or Internet access.
      # Run before the upstream settings merge and runtime credential injection.
      serviceConfig.ExecStartPre = lib.mkBefore [
        "${config.systemd.package}/lib/systemd/systemd-networkd-wait-online --interface=enp2s0:routable --ipv4 --dns=no --timeout=60"
      ];
    };
    # Catch LAN TCP/UDP port-53 requests routed through this gateway before TUN
    # hijacking. Same-L2 DNS servers, encrypted DNS and VPNs are not intercepted.
    networking.nftables.tables.heimdall-dns = {
      family = "ip";
      content = ''
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;
          iifname "enp2s0" ip saddr 192.168.8.0/24 meta l4proto { tcp, udp } th dport 53 counter dnat to 192.168.8.2:53
        }
      '';
    };
    systemd.services.adguardhome-tailnet-webui = {
      description = "Authenticated AdGuard Home UI over Tailnet HTTPS only";
      wantedBy = [ "multi-user.target" ];
      after = [
        "tailscaled.service"
        "tailscaled-set.service"
        "adguardhome.service"
      ];
      requires = [
        "tailscaled.service"
        "adguardhome.service"
      ];
      partOf = [
        "tailscaled.service"
        "adguardhome.service"
      ];
      path = [
        pkgs.coreutils
        pkgs.jq
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = "90s";
        NoNewPrivileges = true;
        ExecStop = "${tailscale} serve --https=8443 --set-path=/ off";
      };
      script = ''
        set -eu
        for attempt in $(seq 1 30); do
          if ${tailscale} status --json | jq -e '.BackendState == "Running"' >/dev/null; then
            exec ${tailscale} serve --bg --https=8443 --set-path=/ --yes http://127.0.0.1:3000
          fi
          sleep 2
        done
        echo 'Native Tailscale did not become ready for AdGuard Serve' >&2
        exit 1
      '';
    };
  };
}
