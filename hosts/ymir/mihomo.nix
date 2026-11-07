{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.dot.networking.proxy;
  enabled = cfg.enable && cfg.backend == "mihomo";
  secretsFile = "${self}/secrets/hosts/ymir/mihomo.yaml";
  seedProvider = pkgs.writeShellApplication {
    name = "mihomo-seed-provider";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      provider="$STATE_DIRECTORY/providers/wgetcloud.yaml"
      marker="$STATE_DIRECTORY/providers/wgetcloud.seed-sha256"
      seed="$CREDENTIALS_DIRECTORY/wgetcloud.yaml"
      seedHash=$(sha256sum "$seed" | cut -d ' ' -f 1)
      install -d -m 0700 "$STATE_DIRECTORY/providers"
      # Keep newer online updates unless the encrypted bootstrap snapshot changes.
      if [[ ! -s "$provider" || ! -f "$marker" || $(< "$marker") != "$seedHash" ]]; then
        install -m 0600 "$seed" "$provider"
        printf '%s\n' "$seedHash" > "$marker"
      fi
    '';
  };
  routing = pkgs.writeShellApplication {
    name = "mihomo-tailnet-routing";
    runtimeInputs = [ pkgs.iproute2 ];
    text = builtins.readFile "${self}/scripts/mihomo-tailnet-routing.sh";
  };
in
{
  config = lib.mkIf enabled {
    dot.networking.proxy.mihomo.configFile = config.sops.templates."ymir-mihomo.yaml".path;

    sops.secrets = {
      mihomo_subscription_url = {
        sopsFile = secretsFile;
        key = "subscription_url";
      };
      mihomo_subscription_nodes = {
        sopsFile = secretsFile;
        key = "subscription_nodes";
        restartUnits = [ "mihomo.service" ];
      };
      mihomo_controller_secret = {
        sopsFile = secretsFile;
        key = "controller_secret";
      };
    };
    sops.templates."ymir-mihomo.yaml" = {
      mode = "0400";
      content =
        builtins.replaceStrings
          [
            "__SUBSCRIPTION_URL__"
            "__CONTROLLER_SECRET__"
          ]
          [
            config.sops.placeholder.mihomo_subscription_url
            config.sops.placeholder.mihomo_controller_secret
          ]
          (builtins.readFile "${self}/config/mihomo/ymir.yaml");
      restartUnits = [ "mihomo.service" ];
    };

    # resolved owns the system stub; only Mihomo decides how upstream DNS is routed.
    # Its bootstrap/node resolvers do not use resolved, avoiding a recursive lookup.
    services.resolved.settings.Resolve = {
      DNS = lib.mkForce [ "127.0.0.1:1053" ];
      Domains = lib.mkForce [
        "~."
        "tail2cfd9e.ts.net"
      ];
      FallbackDNS = lib.mkForce [ ];
      DNSOverTLS = lib.mkForce false;
    };
    networking.networkmanager.unmanaged = [ "interface-name:mihomo" ];
    services.mihomo = {
      processesInfo = true;
      webui = pkgs.metacubexd;
    };

    # Loose reverse-path validation permits the asymmetric TUN/Tailnet policy routes.
    networking.firewall.checkReversePath = "loose";

    systemd.services.mihomo.serviceConfig = {
      LoadCredential = lib.mkForce [
        "config.yaml:${config.services.mihomo.configFile}"
        "wgetcloud.yaml:${config.sops.secrets.mihomo_subscription_nodes.path}"
      ];
      ExecStartPre = [ (lib.getExe seedProvider) ];
    };

    systemd.services.mihomo-tailnet-routing = {
      description = "Separate system Tailscale replies from Mihomo Tailnet outbounds";
      before = [ "mihomo.service" ];
      requiredBy = [ "mihomo.service" ];
      partOf = [ "mihomo.service" ];
      unitConfig.StopWhenUnneeded = true;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${lib.getExe routing} start";
        ExecStop = "${lib.getExe routing} stop";
      };
    };

    assertions = [
      {
        assertion = config.dot.networking.tailscale.enable;
        message = "ymir's Mihomo routing requires the system Tailscale identity for inbound access.";
      }
      {
        assertion = config.dot.networking.tailscale.exitNode == "";
        message = "Disable the system Tailscale exit node before using ymir's Mihomo profile.";
      }
      {
        assertion =
          !config.dot.networking.tailscale.acceptRoutes && !config.dot.networking.tailscale.acceptDns;
        message = "ymir's system Tailscale must not accept subnet routes or override Mihomo DNS.";
      }
    ];
  };
}
