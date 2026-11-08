{ config, lib, ... }:
let
  cfg = config.dot.networking.proxy;
  inherit (cfg) profile;
  inherit (lib) mkOption types;
  tailscale = lib.getExe config.services.tailscale.package;
in
{
  options.dot.networking.proxy.profile.tailnet = {
    domain = mkOption {
      type = types.str;
      default = "";
      description = "MagicDNS domain of the host's Tailnet.";
    };
    hostname = mkOption {
      type = types.str;
      default = "${config.networking.hostName}-${
        if cfg.backend == "sing-box" then "singbox" else cfg.backend
      }";
      description = "Independent embedded Tailscale identity for explicit proxy traffic, not system SSH or Taildrop.";
    };
    webUI = {
      enable = lib.mkEnableOption "node-local Tailscale Serve for the selected proxy controller";
      httpsPort = mkOption {
        type = types.port;
        default = 443;
        description = "Tailnet-only HTTPS port managed by the node-local Serve handler.";
      };
    };
  };

  config = lib.mkIf (cfg.enable && profile.enable) {
    assertions = [
      {
        assertion =
          builtins.match "[A-Za-z0-9][A-Za-z0-9.-]*" profile.tailnet.domain != null
          && builtins.match "[A-Za-z0-9][A-Za-z0-9-]*" profile.tailnet.hostname != null;
        message = "The shared proxy profile requires a Tailnet DNS domain and a valid embedded hostname.";
      }
      {
        assertion =
          config.dot.networking.tailscale.enable
          && config.dot.networking.tailscale.exitNode == ""
          && !config.dot.networking.tailscale.acceptRoutes
          && !config.dot.networking.tailscale.acceptDns;
        message = "The shared proxy profile requires system Tailscale without an exit node, subnet routes or DNS takeover.";
      }
    ];
    # Node-local Serve keeps the system identity; the upstream serve module manages svc: VIPs.
    systemd.services."${cfg.backend}-tailnet-webui" = lib.mkIf profile.tailnet.webUI.enable {
      description = "Expose the authenticated ${cfg.backend} controller over Tailnet HTTPS";
      after = [
        "tailscaled.service"
        "tailscaled-set.service"
        "${cfg.backend}.service"
      ];
      requires = [ "tailscaled.service" ];
      partOf = [ "tailscaled.service" ];
      wantedBy = lib.optionals cfg.autoStart [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = "60s";
        ExecStart = "${tailscale} serve --bg --https=${toString profile.tailnet.webUI.httpsPort} --set-path=/ --yes http://127.0.0.1:${toString profile.ports.controller}";
        ExecStop = "${tailscale} serve --https=${toString profile.tailnet.webUI.httpsPort} --set-path=/ off";
        NoNewPrivileges = true;
      };
    };
  };
}
