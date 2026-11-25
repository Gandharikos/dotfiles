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
  validFilters =
    builtins.isList filters
    && filters != [ ]
    && lib.all (f: builtins.isAttrs f && builtins.isInt (f.id or null) && f.id > 0) filters;
  ids = if validFilters then map (f: toString f.id) filters else [ ];
  seeds =
    if cfg.seedFile != null && builtins.length ids == 1 then
      { ${builtins.head ids} = cfg.seedFile; }
    else
      cfg.seedFiles;
  seedManifest = pkgs.writeText "adguard-filter-seeds.json" (builtins.toJSON seeds);
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
      description = "Legacy public pinned seed for a single declared filter; use seedFiles for multiple filters.";
    };
    seedFiles = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "Public pinned seeds keyed by filter ID; must cover exactly the declared filters. Mutually exclusive with seedFile.";
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
      preStart = lib.mkAfter ''
        ${lib.getExe python} ${self}/scripts/adguardhome-prepare.py \
          "$STATE_DIRECTORY/AdGuardHome.yaml" "$CREDENTIALS_DIRECTORY/users.json" --seeds-json ${seedManifest}
      '';
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
        assertion = (cfg.seedFile != null) != (cfg.seedFiles != { });
        message = "dot.networking.adguardhome requires exactly one of seedFile or seedFiles for offline initialization.";
      }
      {
        assertion =
          validFilters
          && builtins.length (lib.unique ids) == builtins.length ids
          && lib.sort builtins.lessThan ids == builtins.attrNames seeds;
        message = "The AdGuard preset requires unique positive filter IDs and exactly one pinned seed per filter.";
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
