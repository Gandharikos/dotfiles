{
  config,
  lib,
  self,
  ...
}:
let
  cfg = config.dot.networking.proxy;
  inherit (cfg) profile;
  tailscale = lib.getExe config.services.tailscale.package;
  inherit (lib) mkOption types;
in
{
  options.dot.networking.proxy.profile = {
    enable = lib.mkEnableOption "the shared subscription/Tailnet proxy profile";
    secretsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "SOPS file with subscription_nodes, subscription_url and controller_secret keys.";
    };
    tailnet = {
      domain = mkOption {
        type = types.str;
        default = "";
        description = "MagicDNS domain of the host's Tailnet.";
      };
      hostname = mkOption {
        type = types.str;
        default = "${config.networking.hostName}-${
          if cfg.backend == "sing-box" then "singbox" else cfg.backend
        }";
        description = "Independent embedded Tailscale identity, not the system or Rex identity.";
      };
      webUI = {
        enable = lib.mkEnableOption "node-local Tailscale Serve for the selected proxy controller";
        httpsPort = mkOption {
          type = types.port;
          default = 443;
          description = "Tailnet-only HTTPS port managed by the node-local Serve handler.";
        };
      };
    };
    ports = {
      mixed = mkOption {
        type = types.port;
        default = 7890;
        description = "Loopback HTTP/SOCKS proxy port.";
      };
      dns = mkOption {
        type = types.port;
        default = 1053;
        description = "Loopback DNS listener port.";
      };
      controller = mkOption {
        type = types.port;
        default = 9090;
        description = "Loopback authenticated controller port.";
      };
    };
    singBox.template = mkOption {
      type = types.path;
      default = "${self}/config/sing-box/config.json";
      description = "Shared native profile; preserves the selector and rule insertion anchors.";
    };
    singBox.policy = mkOption {
      type = types.path;
      default = "${self}/config/sing-box/policy.yml";
      description = "Public service selectors and inline routing rules in YAML (JSON is also accepted).";
    };
    mihomo.template = mkOption {
      type = types.path;
      default = "${self}/config/mihomo/config.yaml";
      description = "Shared Mihomo base template with host and SOPS credential placeholders.";
    };
    mihomo.policy = mkOption {
      type = types.path;
      default = "${self}/config/mihomo/policy.yaml";
      description = "Public Mihomo proxy groups, rule providers and ordered routing rules; a YAML mapping fragment with keys disjoint from the base template.";
    };
  };

  config = lib.mkIf (cfg.enable && profile.enable) {
    assertions = [
      {
        assertion = builtins.elem cfg.backend [
          "sing-box"
          "mihomo"
        ];
        message = "The shared proxy profile requires the sing-box or mihomo backend.";
      }
      {
        assertion =
          builtins.length (
            lib.unique [
              profile.ports.mixed
              profile.ports.dns
              profile.ports.controller
            ]
          ) == 3;
        message = "The shared proxy profile requires distinct mixed, DNS and controller ports.";
      }
      {
        assertion = profile.secretsFile != null;
        message = "Set dot.networking.proxy.profile.secretsFile to the host's SOPS subscription file.";
      }
      {
        assertion =
          builtins.match "[A-Za-z0-9][A-Za-z0-9.-]*" profile.tailnet.domain != null
          && builtins.match "[A-Za-z0-9][A-Za-z0-9-]*" profile.tailnet.hostname != null;
        message = "The shared proxy profile requires a Tailnet DNS domain and a valid embedded hostname.";
      }
      {
        assertion =
          config.dot.networking.tailscale.enable
          && config.dot.networking.tailscale.exitNode == ""
          && !config.dot.networking.tailscale.acceptRoutes
          && !config.dot.networking.tailscale.acceptDns;
        message = "The shared proxy profile requires system Tailscale without an exit node, subnet routes or DNS takeover.";
      }
    ];
    # Node-local Serve keeps the system identity; the upstream serve module manages svc: VIPs.
    systemd.services."${cfg.backend}-tailnet-webui" = lib.mkIf profile.tailnet.webUI.enable {
      description = "Expose the authenticated ${cfg.backend} controller over Tailnet HTTPS";
      after = [
        "tailscaled.service"
        "tailscaled-set.service"
        "${cfg.backend}.service"
      ];
      requires = [ "tailscaled.service" ];
      partOf = [ "tailscaled.service" ];
      wantedBy = lib.optionals cfg.autoStart [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = "60s";
        ExecStart = "${tailscale} serve --bg --https=${toString profile.tailnet.webUI.httpsPort} --set-path=/ --yes http://127.0.0.1:${toString profile.ports.controller}";
        ExecStop = "${tailscale} serve --https=${toString profile.tailnet.webUI.httpsPort} --set-path=/ off";
        NoNewPrivileges = true;
      };
    };
    services.resolved.settings.Resolve = {
      DNS = lib.mkForce [ "127.0.0.1:${toString profile.ports.dns}" ];
      Domains = lib.mkForce [
        "~."
        profile.tailnet.domain
      ];
      FallbackDNS = lib.mkForce [ ];
      DNSOverTLS = lib.mkForce false;
    };
    networking.networkmanager.unmanaged = [
      "interface-name:${if cfg.backend == "sing-box" then "sb-tun" else "mihomo"}"
    ];
  };
}
