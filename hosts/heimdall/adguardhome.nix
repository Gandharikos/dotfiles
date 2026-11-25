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
  seed = pkgs.fetchurl {
    name = "stevenblack-fakenews-gambling-porn-hosts";
    url = "https://raw.githubusercontent.com/StevenBlack/hosts/81f6c19b6ae322732879d119e5cbdd8f8bf6c52c/alternates/fakenews-gambling-porn/hosts";
    hash = "sha256-KBRgcS+FEUIMj32gGOoWw7VI+FUxY2PUnLik6gN28uU=";
  };
  tailscale = lib.getExe config.services.tailscale.package;
in
{
  config = lib.mkIf enabled {
    dot.networking.adguardhome = {
      enable = true;
      usersFile = config.sops.secrets.adguardhome_users.path;
      seedFile = seed;
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
          # sing-box owns the mapping/cache lifetime of its Fake-IP responses.
          cache_enabled = false;
          cache_size = 0;
          ratelimit = 0;
        };
        filters = [
          {
            # New ID prevents reusing the previous porn-only cached list on upgrade.
            id = 2;
            enabled = true;
            name = "StevenBlack ads, tracking, fakenews, gambling and porn";
            url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts";
          }
        ];
      };
    };
    systemd.services.adguardhome = {
      after = [
        "systemd-resolved.service"
        "sing-box.service"
        "sops-install-secrets.service"
      ];
      wants = [ "sing-box.service" ];
      requires = [ "sops-install-secrets.service" ];
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
