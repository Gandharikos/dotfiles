{ lib, ... }:
let
  inherit (lib.attrsets) filterAttrs optionalAttrs recursiveUpdate;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (lib.types) port str;

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
      hostName = mkOption {
        type = str;
        default = "${cfg.subdomain}.${config.dot.selfhosted.domainSuffix}";
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
in
{
  inherit
    mkProgram
    mkSelfhostedProxyBackends
    mkSelfhostedServiceOptions
    ;
}
