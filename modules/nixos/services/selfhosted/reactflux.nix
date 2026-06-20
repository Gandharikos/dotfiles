{
  config,
  lib,
  pkgs,
  ...
}:
let
  selfhosted = config.dot.selfhosted;
  cfg = selfhosted.services.reactflux;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) package str;

  reactflux = pkgs.stdenvNoCC.mkDerivation {
    pname = "reactflux";
    version = "2026-06-14";

    src = pkgs.fetchFromGitHub {
      owner = "electh";
      repo = "ReactFlux";
      rev = "9cfe5d8bfab9089285504cb87f5d81dd7540b06e";
      hash = "sha256-jS2H1MlwgY4mV7nkZJmfGBthOSQhtdqkQLOiEX4TaSo=";
    };

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -a . "$out/"
      runHook postInstall
    '';
  };

  virtualHostName = if selfhosted.useHttps then cfg.hostName else "http://${cfg.hostName}";
in
{
  options.dot.selfhosted.services.reactflux = {
    enable = mkEnableOption "ReactFlux web frontend for Miniflux" // {
      default = selfhosted.enable && selfhosted.services.miniflux.enable;
    };

    package = mkOption {
      type = package;
      default = reactflux;
      description = "ReactFlux static frontend package.";
    };

    subdomain = mkOption {
      type = str;
      default = "reader";
      description = "Local subdomain used by the reverse proxy.";
    };

    hostName = mkOption {
      type = str;
      default = "${cfg.subdomain}.${selfhosted.domain}";
      description = "Local host name used by the reverse proxy.";
    };
  };

  config = mkIf cfg.enable {
    dot.selfhosted.services.gatus.endpoints = [
      {
        name = "reactflux";
        url = "${if selfhosted.useHttps then "https" else "http"}://${cfg.hostName}";
        interval = "1m";
        conditions = [ "[STATUS] == 200" ];
      }
    ];

    networking.hosts."127.0.0.1" = [ cfg.hostName ];

    services.caddy.virtualHosts.${virtualHostName} = mkIf selfhosted.services.caddy.enable {
      extraConfig = ''
        encode zstd gzip
        root * ${cfg.package}
        try_files {path} {path}/ /index.html
        file_server
      '';
    };

    services.nginx.virtualHosts.${cfg.hostName} = mkIf selfhosted.services.nginx.enable {
      enableACME = selfhosted.useHttps;
      forceSSL = selfhosted.useHttps;
      root = cfg.package;
      locations."/".tryFiles = "$uri $uri/ /index.html";
    };
  };
}
