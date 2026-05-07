{
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib.options) mkOption;
  inherit (lib.types) attrs listOf;
  inherit (lib.strings) escapeShellArg;

  mkSingBoxSettingsImpl =
    { singBoxCfg }:
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

  mkSingBoxGenerateConfigImpl =
    {
      name,
      sourceConfigPath,
      outputConfigPath,
      outputNodesPath,
      singBoxCfg,
    }:
    let
      sub2singboxPkg = self.packages.${pkgs.stdenv.hostPlatform.system}.sub2singbox;
      providersData = {
        subscribes = [
          {
            tag = "clash";
            url = sourceConfigPath;
          }
        ];
        save_config_path = outputNodesPath;
        "Only-nodes" = true;
      };
      baseSettingsFile = pkgs.writeText "${name}-base-settings.json" (
        builtins.toJSON (
          lib.recursiveUpdate (mkSingBoxSettingsImpl { inherit singBoxCfg; }) singBoxCfg.settings
        )
      );
      providersArgFile = pkgs.writeText "${name}-providers-arg.json" (
        builtins.toJSON (builtins.toJSON providersData)
      );
      mergeScript = pkgs.writeText "${name}-merge.py" ''
        import json
        import pathlib
        import sys

        base_path = pathlib.Path(sys.argv[1])
        nodes_path = pathlib.Path(sys.argv[2])
        output_path = pathlib.Path(sys.argv[3])

        def dedupe(items):
            seen = set()
            result = []
            for item in items:
                if item and item not in seen:
                    seen.add(item)
                    result.append(item)
            return result

        base = json.loads(base_path.read_text())
        nodes = json.loads(nodes_path.read_text()) if nodes_path.exists() else []
        if not isinstance(nodes, list):
            raise SystemExit("sub2singbox did not return a node list")

        existing_outbounds = base.get("outbounds") or []
        builtin_tags = ("direct", "block", "dns-out")
        reserved_tags = set(builtin_tags) | {"select", "auto"}
        non_selectable_types = {"selector", "urltest", "direct", "block", "dns"}

        staged_outbounds = []
        terminal_outbounds = {}
        existing_tags = set()
        for outbound in existing_outbounds:
            tag = outbound.get("tag")
            if tag:
                existing_tags.add(tag)
            if tag in builtin_tags:
                terminal_outbounds[tag] = outbound
            else:
                staged_outbounds.append(outbound)

        generated_outbounds = []
        generated_tags = set()
        for outbound in nodes:
            tag = outbound.get("tag")
            if not tag or tag in reserved_tags or tag in existing_tags or tag in generated_tags:
                continue
            generated_tags.add(tag)
            generated_outbounds.append(outbound)

        selectable_tags = dedupe(
            [
                outbound.get("tag")
                for outbound in staged_outbounds + generated_outbounds
                if outbound.get("tag") and outbound.get("type") not in non_selectable_types
            ]
        )

        default_selection = "direct"
        selector_members = ["direct"]
        auto_members = ["direct"]
        if selectable_tags:
            default_selection = "auto"
            selector_members = ["auto", *selectable_tags, "direct"]
            auto_members = selectable_tags

        select_outbound = next((outbound for outbound in staged_outbounds if outbound.get("tag") == "select"), None)
        if select_outbound is None:
            select_outbound = {"type": "selector", "tag": "select"}
            staged_outbounds.insert(0, select_outbound)
        select_outbound["default"] = default_selection
        select_outbound["outbounds"] = selector_members

        auto_outbound = next((outbound for outbound in staged_outbounds if outbound.get("tag") == "auto"), None)
        if auto_outbound is None:
            auto_outbound = {
                "type": "urltest",
                "tag": "auto",
                "url": "https://cp.cloudflare.com/generate_204",
                "interval": "10m",
            }
            insert_at = 1 if staged_outbounds and staged_outbounds[0].get("tag") == "select" else 0
            staged_outbounds.insert(insert_at, auto_outbound)
        auto_outbound["outbounds"] = auto_members
        auto_outbound.setdefault("url", "https://cp.cloudflare.com/generate_204")
        auto_outbound.setdefault("interval", "10m")

        terminal_outbounds.setdefault("direct", {"type": "direct", "tag": "direct"})
        terminal_outbounds.setdefault("block", {"type": "block", "tag": "block"})
        terminal_outbounds.setdefault("dns-out", {"type": "dns", "tag": "dns-out"})

        base["outbounds"] = staged_outbounds + generated_outbounds + [
            terminal_outbounds["direct"],
            terminal_outbounds["block"],
            terminal_outbounds["dns-out"],
        ]

        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(json.dumps(base, indent=2, ensure_ascii=False) + "\n")
        if nodes_path.exists():
            nodes_path.unlink()
      '';
    in
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [
        pkgs.coreutils
        pkgs.python3
        sub2singboxPkg
      ];
      text = ''
        set -euo pipefail
        umask 077

        if [ ! -r ${escapeShellArg sourceConfigPath} ]; then
          echo "proxy source config not readable: ${sourceConfigPath}" >&2
          exit 1
        fi

        mkdir -p "$(dirname ${escapeShellArg outputConfigPath})"
        mkdir -p "$(dirname ${escapeShellArg outputNodesPath})"

        temp_json_data="$(tr -d '\n' < ${providersArgFile})"
        ${sub2singboxPkg}/bin/sub2singbox --template_index=0 --temp_json_data "$temp_json_data"
        python ${mergeScript} ${escapeShellArg baseSettingsFile} ${escapeShellArg outputNodesPath} ${escapeShellArg outputConfigPath}
      '';
    };

  mkSingBoxSettings = args: mkSingBoxSettingsImpl (builtins.removeAttrs args [ "pkgs" ]);

  mkSingBoxGenerateConfig = args: mkSingBoxGenerateConfigImpl (builtins.removeAttrs args [ "pkgs" ]);
in
{
  options.dot.networking.proxy.singBox = {
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

  config._module.args.proxyCommon = {
    inherit
      mkSingBoxGenerateConfig
      mkSingBoxSettings
      ;
  };
}
