{
  lib,
  config,
  pkgs,
  self,
  ...
}:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) attrs enum listOf;
  inherit (lib) mkIf mkMerge;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  cfg = config.my.networking.proxy;

  proxyConfigPath =
    if isDarwin || config.my.gui.enable then
      "${config.my.home}/.config/clash-verge/config.yaml"
    else
      "/var/lib/mihomo/config.yaml";
  proxyConfigOwner = if isDarwin || config.my.gui.enable then config.my.name else "mihomo";
  proxyConfigGroup =
    if isDarwin then
      "staff"
    else if config.my.gui.enable then
      "users"
    else
      "mihomo";
  proxyConfigMode = if isDarwin || config.my.gui.enable then "0600" else "0400";

  mkSingBoxSettings =
    { pkgs, singBoxCfg }:
    let
      extraOutboundTags = map (outbound: outbound.tag) (
        builtins.filter (outbound: outbound ? tag) singBoxCfg.extraOutbounds
      );
      autoOutboundTags = if extraOutboundTags == [ ] then [ "direct" ] else extraOutboundTags;
      selectorOutbounds =
        if extraOutboundTags == [ ] then [ "direct" ] else [ "auto" ] ++ extraOutboundTags ++ [ "direct" ];
    in
    {
      log = {
        level = "info";
        timestamp = true;
      };

      experimental = {
        clash_api = {
          external_controller = "127.0.0.1:9090";
          external_ui = "${pkgs.metacubexd}";
          default_mode = "rule";
        };

        cache_file = {
          enabled = true;
          path = "cache.db";
          store_fakeip = true;
        };
      };

      dns = {
        servers = [
          {
            tag = "proxydns";
            address = "tls://8.8.8.8";
            detour = "select";
          }
          {
            tag = "localdns";
            address = "h3://223.5.5.5/dns-query";
            detour = "direct";
          }
          {
            tag = "dns_fakeip";
            address = "fakeip";
          }
        ];

        rules = [
          {
            clash_mode = "Global";
            server = "proxydns";
          }
          {
            clash_mode = "Direct";
            server = "localdns";
          }
          {
            rule_set = [ "geosite-cn" ];
            server = "localdns";
          }
          {
            rule_set = [ "geosite-geolocation-!cn" ];
            server = "proxydns";
          }
          {
            rule_set = [ "geosite-geolocation-!cn" ];
            query_type = [
              "A"
              "AAAA"
            ];
            server = "dns_fakeip";
          }
        ];

        fakeip = {
          enabled = true;
          inet4_range = "198.18.0.0/15";
          inet6_range = "fc00::/18";
        };

        independent_cache = true;
        final = "proxydns";
      };

      inbounds = [
        {
          type = "tun";
          tag = "tun-in";
          address = [
            "172.19.0.1/30"
            "fd00::1/126"
          ];
          auto_route = true;
          strict_route = true;
          sniff = true;
          sniff_override_destination = true;
          domain_strategy = "prefer_ipv4";
        }
      ];

      outbounds = [
        {
          type = "selector";
          tag = "select";
          default = if extraOutboundTags == [ ] then "direct" else "auto";
          outbounds = selectorOutbounds;
        }
        {
          type = "urltest";
          tag = "auto";
          outbounds = autoOutboundTags;
          url = "https://cp.cloudflare.com/generate_204";
          interval = "10m";
        }
      ]
      ++ singBoxCfg.extraOutbounds
      ++ [
        {
          type = "direct";
          tag = "direct";
        }
        {
          type = "block";
          tag = "block";
        }
        {
          type = "dns";
          tag = "dns-out";
        }
      ];

      route = {
        auto_detect_interface = true;
        rule_set = [
          {
            tag = "geosite-cn";
            type = "remote";
            format = "binary";
            url = "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite-cn.srs";
            download_detour = "direct";
          }
          {
            tag = "geosite-geolocation-!cn";
            type = "remote";
            format = "binary";
            url = "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite-geolocation-!cn.srs";
            download_detour = "direct";
          }
          {
            tag = "geoip-cn";
            type = "remote";
            format = "binary";
            url = "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geoip-cn.srs";
            download_detour = "direct";
          }
          {
            tag = "geoip-private";
            type = "remote";
            format = "binary";
            url = "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geoip-private.srs";
            download_detour = "direct";
          }
        ]
        ++ singBoxCfg.extraRuleSets;

        rules = [
          {
            protocol = "dns";
            outbound = "dns-out";
          }
          {
            clash_mode = "Direct";
            outbound = "direct";
          }
          {
            clash_mode = "Global";
            outbound = "select";
          }
          {
            rule_set = [
              "geoip-private"
              "geoip-cn"
              "geosite-cn"
            ];
            outbound = "direct";
          }
        ]
        ++ singBoxCfg.extraRouteRules;

        final = "select";
      };
    };
in
{
  options.my.networking.proxy = {
    enable = mkEnableOption "proxy service (mihomo or sing-box)" // {
      default = true;
    };

    autoStart = mkEnableOption "auto start proxy on boot (NixOS only)" // {
      default = false;
    };

    backend = mkOption {
      type = enum [
        "mihomo"
        "sing-box"
      ];
      default = "mihomo";
      description = "Proxy backend to activate for this host.";
    };

    singBox = {
      extraOutbounds = mkOption {
        type = listOf attrs;
        default = [ ];
        description = "Additional sing-box outbounds appended to the generated base profile.";
      };

      extraRouteRules = mkOption {
        type = listOf attrs;
        default = [ ];
        description = "Additional sing-box route rules appended after the base rules.";
      };

      extraRuleSets = mkOption {
        type = listOf attrs;
        default = [ ];
        description = "Additional remote or local sing-box rule sets.";
      };

      settings = mkOption {
        type = attrs;
        default = { };
        description = "Recursive override layer for the generated sing-box settings.";
      };
    };
  };

  config = mkMerge [
    {
      _module.args.proxyCommon = {
        inherit mkSingBoxSettings;
      };
    }

    (mkIf (cfg.enable && cfg.backend == "mihomo") {
      sops.secrets.proxy_config = {
        sopsFile = "${self}/secrets/services/clash.yaml";
        key = "clash_config";
        path = proxyConfigPath;
        owner = proxyConfigOwner;
        group = proxyConfigGroup;
        mode = proxyConfigMode;
      };
    })
  ];
}
