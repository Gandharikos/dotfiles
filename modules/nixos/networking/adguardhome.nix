# Opt-in authenticated DNS filtering. Hosts own addresses, upstreams and exposure.
{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.dot.networking.adguardhome;
  settings = config.services.adguardhome.settings;
  filters = settings.filters or [ ];
  python = pkgs.python3.withPackages (p: [ p.pyyaml ]);
in
{
  options.dot.networking.adguardhome = {
    enable = lib.mkEnableOption "authenticated AdGuard Home with a pinned initial filter cache";
    usersFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Absolute runtime path to a JSON array of admin names/bcrypt hashes; never a Nix-store secret.";
    };
    seedFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Public pinned seed for the single filter declared in services.adguardhome.settings.filters.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.adguardhome = {
      enable = true;
      openFirewall = false;
      allowDHCP = false;
      mutableSettings = true;
      settings = {
        http = {
          doh.insecure_enabled = false;
          pprof.enabled = false;
        };
        tls.enabled = false;
        dhcp.enabled = false;
        dns = {
          fallback_dns = [ ];
          use_private_ptr_resolvers = false;
          local_ptr_upstreams = [ ];
        };
        clients.runtime_sources.rdns = false;
        filtering = {
          protection_enabled = true;
          filtering_enabled = true;
          blocking_mode = "null_ip";
          blocked_response_ttl = 60;
          filters_update_interval = 24;
          parental_enabled = false;
          safebrowsing_enabled = false;
        };
        # Local query metadata is retained for one day, not exported to cloud checks.
        querylog = {
          enabled = true;
          interval = "24h";
        };
        statistics = {
          enabled = true;
          interval = "24h";
        };
      };
    };
    systemd.services.adguardhome = {
      serviceConfig.LoadCredential = lib.optional (cfg.usersFile != null) "users.json:${cfg.usersFile}";
      preStart = lib.mkAfter (
        lib.optionalString (cfg.seedFile != null) ''
          ${lib.getExe python} ${self}/scripts/adguardhome-prepare.py \
            "$STATE_DIRECTORY/AdGuardHome.yaml" "$CREDENTIALS_DIRECTORY/users.json" ${cfg.seedFile}
        ''
      );
    };
    assertions = [
      {
        assertion =
          cfg.usersFile != null
          && lib.hasPrefix "/" cfg.usersFile
          && !(lib.hasPrefix "/nix/store/" cfg.usersFile);
        message = "dot.networking.adguardhome.usersFile must name a runtime credential file outside the Nix store.";
      }
      {
        assertion = cfg.seedFile != null;
        message = "dot.networking.adguardhome.seedFile is required for offline filter initialization.";
      }
      {
        assertion =
          builtins.isList filters
          && builtins.length filters == 1
          && builtins.isAttrs (builtins.head filters)
          && builtins.isInt ((builtins.head filters).id or null)
          && (builtins.head filters).id > 0;
        message = "The AdGuard preset requires one declared filter with a positive integer ID matching its seed.";
      }
      {
        assertion =
          lib.hasPrefix "127.0.0.1:" settings.http.address || lib.hasPrefix "[::1]:" settings.http.address;
        message = "The AdGuard preset requires an explicit loopback HTTP address; hosts own authenticated exposure.";
      }
      {
        assertion = (settings.dns.bind_hosts or [ ]) != [ ] && (settings.dns.upstream_dns or [ ]) != [ ];
        message = "The AdGuard preset requires explicit DNS bind_hosts and upstream_dns; it does not select a gateway or proxy.";
      }
    ];
  };
}
