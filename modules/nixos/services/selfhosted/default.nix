{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.selfhosted;
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool enum str;

  proxyBackends = lib.dot.mkSelfhostedProxyBackends config;
  proxyHostNames = map (service: service.hostName) (attrValues proxyBackends);

  backupPackage =
    {
      inherit (pkgs) restic;
      borg = pkgs.borgbackup;
    }
    .${cfg.backup};

  selfhostedExport = pkgs.writeShellApplication {
    name = "selfhosted-export";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      gnutar
      postgresql
      sudo
      systemd
      zstd
    ];
    text = ''
      if [ "$(id -u)" != 0 ]; then
        echo "selfhosted-export must be run as root" >&2
        exit 1
      fi

      output="''${1:-/var/backup/selfhosted/selfhosted-$(date -u +%Y%m%dT%H%M%SZ).tar.zst}"
      workdir="$(mktemp -d)"
      trap 'rm -rf "$workdir"' EXIT

      mkdir -p "$(dirname "$output")" "$workdir/postgresql" "$workdir/var/lib"

      if systemctl is-active --quiet postgresql.service; then
        sudo -u postgres pg_dumpall --globals-only | tee "$workdir/postgresql/globals.sql" > /dev/null
        sudo -u postgres psql -Atqc "SELECT datname FROM pg_database WHERE datname IN ('miniflux', 'vaultwarden', 'wakapi')" \
          | while IFS= read -r database; do
              [ -n "$database" ] || continue
              sudo -u postgres pg_dump --format=custom "$database" \
                | tee "$workdir/postgresql/$database.dump" > /dev/null
            done
      fi

      for directory in forgejo vaultwarden ntfy-sh wakapi; do
        if [ -e "/var/lib/$directory" ]; then
          tar -C /var/lib -cpf "$workdir/var/lib/$directory.tar" "$directory"
        fi
      done

      tar -C "$workdir" --zstd -cpf "$output" .
      echo "$output"
    '';
  };
in
{
  imports = lib.dot.scanPaths ./.;

  options.dot.selfhosted = {
    enable = mkEnableOption "self-hosted services" // {
      default = config.dot.device.type == "server";
    };

    domain = mkOption {
      type = str;
      default = "localhost";
      description = "Domain used for self-hosted reverse-proxy host names.";
    };

    useHttps = mkOption {
      type = bool;
      default = cfg.domain != "localhost";
      description = "Whether reverse proxies should serve self-hosted domains over HTTPS.";
    };

    reverseProxy = mkOption {
      type = enum [
        "caddy"
        "nginx"
      ];
      default = "caddy";
      description = "Reverse proxy implementation for self-hosted services.";
    };

    backup = mkOption {
      type = enum [
        "restic"
        "borg"
      ];
      default = "restic";
      description = "Backup tool preference for self-hosted service data.";
    };

    monitoring = mkOption {
      type = enum [
        "uptime-kuma"
        "gatus"
      ];
      default = "gatus";
      description = "Monitoring service to deploy for self-hosted services.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = [
        backupPackage
        selfhostedExport
      ];
      networking.hosts."127.0.0.1" = proxyHostNames;
    }
  ]);
}
