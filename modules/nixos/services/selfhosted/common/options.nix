{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.selfhosted;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types)
    attrsOf
    bool
    enum
    port
    str
    submodule
    ;
in
{
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

    proxyBackends = mkOption {
      type = attrsOf (submodule {
        options = {
          host = mkOption {
            type = str;
            description = "Address the self-hosted service listens on.";
          };

          port = mkOption {
            type = port;
            description = "Port the self-hosted service listens on.";
          };

          scheme = mkOption {
            type = enum [
              "http"
              "https"
            ];
            description = "Scheme used by the reverse proxy to reach the service.";
          };

          hostName = mkOption {
            type = str;
            description = "Public host name used by the reverse proxy.";
          };

          localHostAlias = mkOption {
            type = bool;
            description = "Whether this service host name is mapped to localhost on the host machine.";
          };
        };
      });
      default = { };
      description = "Reverse-proxy backend definitions contributed by self-hosted services.";
    };
  };
}
