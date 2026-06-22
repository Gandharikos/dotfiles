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
  inherit (lib.types) bool package str;

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
  configuredPackage = pkgs.runCommand "reactflux-configured-${reactflux.version}" { } ''
    cp -a ${cfg.package} "$out"
    chmod -R u+w "$out"
    substituteInPlace "$out/index.html" \
      --replace-fail '</head>' '<script>
        (() => {
          if (${builtins.toJSON cfg.autoConfigureServer} && location.pathname === "/" && location.search === "") {
            location.replace("/?server=" + encodeURIComponent(${builtins.toJSON cfg.serverUrl}));
          }
        })();
      </script></head>'
  '';
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

    serverUrl = mkOption {
      type = str;
      default = "https://${selfhosted.services.miniflux.hostName}";
      description = "Miniflux server URL prefilled on the ReactFlux login page.";
    };

    autoConfigureServer = mkOption {
      type = bool;
      default = true;
      description = "Whether to prefill the Miniflux server URL for ReactFlux.";
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
        root * ${configuredPackage}
        try_files {path} {path}/ /index.html
        file_server
      '';
    };

    services.nginx.virtualHosts.${cfg.hostName} = mkIf selfhosted.services.nginx.enable {
      enableACME = selfhosted.useHttps;
      forceSSL = selfhosted.useHttps;
      root = configuredPackage;
      locations."/".tryFiles = "$uri $uri/ /index.html";
    };
  };
}
