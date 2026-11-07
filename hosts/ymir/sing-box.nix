{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.dot.networking.proxy;
  enabled = cfg.enable && cfg.backend == "sing-box";
  secretsFile = "${self}/secrets/hosts/ymir/mihomo.yaml";
  python = pkgs.python3.withPackages (p: [ p.pyyaml ]);
  base = pkgs.writeText "ymir-sing-box-base.json" (
    builtins.replaceStrings [ "__WEBUI_PATH__" ] [ "${pkgs.metacubexd}" ] (
      builtins.readFile "${self}/config/sing-box/ymir.json"
    )
  );
  subscription = pkgs.writeShellApplication {
    name = "ymir-sing-box-subscription";
    runtimeInputs = [
      pkgs.curl
      pkgs.iproute2
    ];
    text = ''
      exec ${lib.getExe python} ${self}/scripts/sing-box-subscription.py "$@" \
        --base ${base} \
        --state "$STATE_DIRECTORY" \
        --credentials "$CREDENTIALS_DIRECTORY" \
        --output /run/sing-box/config.json \
        --core ${lib.getExe config.services.sing-box.package}
    '';
  };
  credentials = [
    "nodes.yaml:${config.sops.secrets.singbox_subscription_nodes.path}"
    "controller-secret:${config.sops.secrets.singbox_controller_secret.path}"
    "subscription-url:${config.sops.secrets.singbox_subscription_url.path}"
  ];
  routing = pkgs.writeShellApplication {
    name = "sing-box-tailnet-routing";
    runtimeInputs = [ pkgs.iproute2 ];
    # Both alternative cores use table 2022; only the selected backend owns the rules.
    text = builtins.readFile "${self}/scripts/mihomo-tailnet-routing.sh";
  };
in
{
  config = lib.mkIf enabled {
    dot.networking.proxy.singBox.configFile = "/run/sing-box/config.json";
    sops.secrets = {
      singbox_subscription_nodes = {
        sopsFile = secretsFile;
        key = "subscription_nodes";
        restartUnits = [ "sing-box.service" ];
      };
      singbox_controller_secret = {
        sopsFile = secretsFile;
        key = "controller_secret";
        restartUnits = [ "sing-box.service" ];
      };
      singbox_subscription_url = {
        sopsFile = secretsFile;
        key = "subscription_url";
      };
    };

    services.resolved.settings.Resolve = {
      DNS = lib.mkForce [ "127.0.0.1:1053" ];
      Domains = lib.mkForce [
        "~."
        "tail2cfd9e.ts.net"
      ];
      FallbackDNS = lib.mkForce [ ];
      DNSOverTLS = lib.mkForce false;
    };
    networking.networkmanager.unmanaged = [ "interface-name:sb-tun" ];

    systemd.services.sing-box = {
      # The upstream oneshot is not otherwise rerun when only its flags change on switch.
      after = [ "tailscaled-set.service" ];
      requires = [ "tailscaled-set.service" ];
      serviceConfig = {
        LoadCredential = credentials;
        ExecStartPre = [ "${lib.getExe subscription} generate" ];
        UMask = "0077";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };
    systemd.services.sing-box-subscription = {
      description = "Refresh ymir's sing-box nodes directly, keeping the last valid subscription on failure";
      after = [
        "network-online.target"
        "sops-install-secrets.service"
      ];
      wants = [ "network-online.target" ];
      requires = [ "sops-install-secrets.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "sing-box";
        Group = "sing-box";
        StateDirectory = "sing-box";
        StateDirectoryMode = "0700";
        LoadCredential = credentials;
        ExecStart = "${lib.getExe subscription} update";
        ExecStartPost = "+${pkgs.systemd}/bin/systemctl try-restart sing-box.service";
        UMask = "0077";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        CapabilityBoundingSet = [ "CAP_NET_RAW" ];
        AmbientCapabilities = [ "CAP_NET_RAW" ];
      };
    };
    systemd.timers.sing-box-subscription = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "15m";
        OnUnitActiveSec = "1d";
        RandomizedDelaySec = "5m";
      };
    };
    systemd.services.sing-box-tailnet-routing = {
      description = "Preserve system Tailscale replies alongside sing-box Tailnet outbounds";
      before = [ "sing-box.service" ];
      requiredBy = [ "sing-box.service" ];
      partOf = [ "sing-box.service" ];
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
        assertion =
          config.dot.networking.tailscale.enable && config.dot.networking.tailscale.exitNode == "";
        message = "ymir's sing-box profile requires system Tailscale without an exit node.";
      }
      {
        assertion =
          !config.dot.networking.tailscale.acceptRoutes && !config.dot.networking.tailscale.acceptDns;
        message = "System Tailscale must not override the sing-box DNS/subnet routing policy.";
      }
      {
        assertion = !config.services.mihomo.enable;
        message = "Do not run ymir's sing-box and Mihomo TUN/controller simultaneously.";
      }
    ];
  };
}
