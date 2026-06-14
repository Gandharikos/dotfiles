{
  config,
  lib,
  ...
}:
let
  selfhosted = config.dot.selfhosted;
  cfg = config.dot.selfhosted.services.nginx;
  inherit (lib.attrsets) attrValues mapAttrs' nameValuePair;
  inherit (lib.lists) optionals;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;

  proxyBackends = lib.dot.mkSelfhostedProxyBackends config;
  proxyHostNames = map (service: service.hostName) (attrValues proxyBackends);
  proxyTarget = service: "${service.scheme}://${service.host}:${toString service.port}";
  virtualHosts = mapAttrs' (
    _: service:
    nameValuePair service.hostName {
      enableACME = selfhosted.useHttps;
      forceSSL = selfhosted.useHttps;
      locations."/" = {
        proxyPass = proxyTarget service;
        proxyWebsockets = true;
        extraConfig = lib.optionalString (service.scheme == "https") ''
          proxy_ssl_verify off;
        '';
      };
    }
  ) proxyBackends;
in
{
  options.dot.selfhosted.services.nginx.enable = mkEnableOption "Nginx for self-hosted services" // {
    default = config.dot.selfhosted.enable && config.dot.selfhosted.reverseProxy == "nginx";
  };

  config = mkIf cfg.enable {
    security.acme = mkIf selfhosted.useHttps {
      acceptTerms = true;
      defaults.email = config.dot.admin.email;
    };

    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      inherit virtualHosts;
    };

    networking.firewall.allowedTCPPorts =
      optionals (proxyHostNames != [ ]) [ 80 ]
      ++ optionals (proxyHostNames != [ ] && selfhosted.useHttps) [ 443 ];
  };
}
