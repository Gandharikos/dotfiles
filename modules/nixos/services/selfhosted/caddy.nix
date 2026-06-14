{
  config,
  lib,
  pkgs,
  ...
}:
let
  selfhosted = config.dot.selfhosted;
  cfg = config.dot.selfhosted.services.caddy;
  inherit (lib.attrsets) mapAttrs' nameValuePair optionalAttrs;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;

  proxyBackends = lib.dot.mkSelfhostedProxyBackends config;
  virtualHostName =
    service: if selfhosted.useHttps then service.hostName else "http://${service.hostName}";
  proxyTarget = service: "${service.scheme}://${service.host}:${toString service.port}";
  mkProxyVirtualHost = service: {
    extraConfig = ''
      encode zstd gzip
      reverse_proxy ${proxyTarget service} ${
        lib.optionalString (service.scheme == "https") ''
          {
            transport http {
              tls_insecure_skip_verify
            }
          }
        ''
      }
    '';
  };
  virtualHosts = mapAttrs' (
    _: service: nameValuePair (virtualHostName service) (mkProxyVirtualHost service)
  ) proxyBackends;
  localVaultwardenHost =
    optionalAttrs (selfhosted.domain == "localhost" && selfhosted.services.vaultwarden.enable)
      {
        "http://localhost" = mkProxyVirtualHost selfhosted.services.vaultwarden;
      };
in
{
  options.dot.selfhosted.services.caddy.enable = mkEnableOption "Caddy for self-hosted services" // {
    default = config.dot.selfhosted.enable && config.dot.selfhosted.reverseProxy == "caddy";
  };

  config = mkIf cfg.enable {
    environment = {
      shellAliases = {
        caddy-log = "journalctl _SYSTEMD_UNIT=caddy.service";
      };
      systemPackages = [ pkgs.caddy ];
    };

    services.caddy = {
      enable = true;
      email = config.dot.admin.email;
      virtualHosts = virtualHosts // localVaultwardenHost;
    };

    networking.firewall.allowedTCPPorts =
      if selfhosted.useHttps then
        [
          80
          443
        ]
      else
        [ 80 ];
  };
}
