{
  config,
  lib,
  self,
  ...
}:
let
  cfg = config.dot.networking.proxy;
  inherit (cfg) profile;
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
    ];
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
