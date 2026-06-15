{ lib, ... }:
let
  inherit (lib.attrsets) filterAttrs optionalAttrs recursiveUpdate;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (lib.types) enum port str;

  mkProgram =
    pkgs: name: extraConfig:
    recursiveUpdate {
      enable = mkEnableOption "Enable ${name}";
      package = mkPackageOption pkgs name { };
    } extraConfig;

  mkSelfhostedServiceOptions =
    {
      config,
      name,
      defaultPort,
      displayName ? name,
      subdomain ? displayName,
      defaultEnable ? config.dot.selfhosted.enable,
      scheme ? "http",
    }:
    let
      cfg = config.dot.selfhosted.services.${name};
    in
    {
      enable = mkEnableOption displayName // {
        default = defaultEnable;
      };
      host = mkOption {
        type = str;
        default = "127.0.0.1";
        description = "Address ${displayName} listens on.";
      };
      port = mkOption {
        type = port;
        default = defaultPort;
        description = "Port ${displayName} listens on.";
      };
      subdomain = mkOption {
        type = str;
        default = subdomain;
        description = "Local subdomain used by the reverse proxy.";
      };
      scheme = mkOption {
        type = enum [
          "http"
          "https"
        ];
        default = scheme;
        description = "Scheme used by the reverse proxy to reach ${displayName}.";
      };
      hostName = mkOption {
        type = str;
        default = "${cfg.subdomain}.${config.dot.selfhosted.domain}";
        description = "Local host name used by the reverse proxy.";
      };
    };

  mkSelfhostedProxyBackends =
    config:
    let
      cfg = config.dot.selfhosted;
    in
    filterAttrs (_: service: service.enable) (
      {
        inherit (cfg.services)
          vaultwarden
          forgejo
          ntfy
          miniflux
          wakapi
          linkwarden
          kanidm
          jellyfin
          calibre
          ;
      }
      // optionalAttrs cfg.services.uptimeKuma.enable {
        uptimeKuma = cfg.services.uptimeKuma;
      }
      // optionalAttrs cfg.services.gatus.enable {
        gatus = cfg.services.gatus;
      }
    );

  mkSelfhostedExportPackage =
    pkgs:
    pkgs.writeShellApplication {
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
          sudo -u postgres psql -Atqc "SELECT datname FROM pg_database WHERE datname IN ('miniflux', 'vaultwarden', 'wakapi', 'linkwarden', 'roundcube')" \
            | while IFS= read -r database; do
                [ -n "$database" ] || continue
                sudo -u postgres pg_dump --format=custom "$database" \
                  | tee "$workdir/postgresql/$database.dump" > /dev/null
              done
        fi

        for directory in forgejo kanidm vaultwarden ntfy-sh wakapi linkwarden mailserver roundcube; do
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
  inherit
    mkProgram
    mkSelfhostedExportPackage
    mkSelfhostedProxyBackends
    mkSelfhostedServiceOptions
    ;
}
