{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.dot.networking.proxy;
  inherit (cfg) profile;
  enabled = cfg.enable && profile.enable && cfg.backend == "mihomo";
  inherit (profile) secretsFile;
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
    dot.networking.proxy.mihomo.configFile = config.sops.templates."proxy-mihomo.yaml".path;

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
    sops.templates."proxy-mihomo.yaml" = {
      mode = "0400";
      # Nix substitutes public parameters and SOPS markers; sops-nix fills secrets at activation.
      content =
        builtins.replaceStrings
          [
            "__SUBSCRIPTION_URL__"
            "__CONTROLLER_SECRET__"
            "__TAILNET_DOMAIN__"
            "__TAILNET_HOSTNAME__"
            "__SYSTEM_TAILSCALE_INTERFACE__"
            "__MIXED_PORT__"
            "__DNS_PORT__"
            "__CONTROLLER_PORT__"
          ]
          [
            config.sops.placeholder.mihomo_subscription_url
            config.sops.placeholder.mihomo_controller_secret
            profile.tailnet.domain
            profile.tailnet.hostname
            config.services.tailscale.interfaceName
            (toString profile.ports.mixed)
            (toString profile.ports.dns)
            (toString profile.ports.controller)
          ]
          (
            lib.concatStringsSep "\n" [
              (builtins.readFile profile.mihomo.template)
              (builtins.readFile profile.mihomo.policy)
            ]
          );
      restartUnits = [ "mihomo.service" ];
    };

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
        assertion = !config.services.sing-box.enable;
        message = "Do not run sing-box and Mihomo TUN/controller simultaneously.";
      }
    ];
  };
}
