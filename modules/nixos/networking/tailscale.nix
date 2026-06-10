{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (config) dot;
  inherit (lib.modules)
    mkIf
    mkDefault
    mkBefore
    mkForce
    ;
  inherit (lib.lists) optionals;
  inherit (lib.strings) concatStringsSep;

  cfg = config.dot.networking.tailscale;
  isClient = cfg.role == "client";
  isSubnetRouter = builtins.elem cfg.role [
    "subnet-router"
    "router-exit-node"
  ];
  isExitNode = builtins.elem cfg.role [
    "exit-node"
    "router-exit-node"
  ];
  isRoutingServer = isSubnetRouter || isExitNode;
  advertiseRoutesFlag = optionals (isSubnetRouter && cfg.advertiseRoutes != [ ]) [
    "--advertise-routes=${concatStringsSep "," cfg.advertiseRoutes}"
  ];
  boolFlag = name: value: "--${name}=${if value then "true" else "false"}";
  routeAndDnsFlags = [
    (boolFlag "accept-dns" cfg.acceptDns)
    (boolFlag "accept-routes" cfg.acceptRoutes)
  ];
in
{
  config = mkIf cfg.enable {
    sops.secrets = mkIf cfg.autoConnect {
      tailscale_authKey = {
        sopsFile = "${self}/secrets/services/tailscale.yaml";
      };
    };

    environment.systemPackages = [ pkgs.tailscale ];
    networking.firewall = {
      # Always allow all traffic from the Tailscale virtual interface
      trustedInterfaces = [ "${config.services.tailscale.interfaceName}" ];
    };

    services.tailscale = {
      enable = true;

      # Setting this to true automatically handles opening the required UDP ports
      openFirewall = true;

      authKeyFile = mkIf cfg.autoConnect config.sops.secrets.tailscale_authKey.path;

      # Apply role-specific Tailscale behavior declaratively.
      extraUpFlags =
        cfg.defaultFlags
        ++ routeAndDnsFlags
        ++ optionals isExitNode [
          "--advertise-exit-node"
        ]
        ++ advertiseRoutesFlag
        ++ optionals isRoutingServer [
          "--operator=${dot.primaryUser}"
        ];

      # Modern NixOS prefers declarative state management via extraSetFlags over extraUpFlags
      extraSetFlags =
        cfg.defaultFlags
        ++ routeAndDnsFlags
        ++ optionals isExitNode [
          "--advertise-exit-node"
        ]
        ++ advertiseRoutesFlag
        ++ optionals isRoutingServer [
          "--operator=${dot.primaryUser}"
        ];

      # Graceful integration with Caddy to acquire certificates from the tailscale daemon
      # - https://tailscale.com/blog/caddy
      permitCertUid = "root";

      useRoutingFeatures = mkDefault (if isClient then "client" else "server");
    };

    systemd = {
      network.wait-online.ignoredInterfaces = [ "${config.services.tailscale.interfaceName}" ];
      services = {
        tailscaled.serviceConfig.Environment = mkBefore [ "TS_NO_LOGS_NO_SUPPORT=true" ];
        tailscaled-autoconnect = mkIf cfg.autoConnect {
          after = [ "sops-install-secrets.service" ];
          wants = [ "sops-install-secrets.service" ];
          wantedBy = mkForce [ ];
          serviceConfig = {
            # Global systemd defaults are 15s on this host, which is too short when Wi-Fi
            # brings up the default route after tailscaled has already started.
            TimeoutStartSec = "2min";
          };
        };
      };
      timers.tailscaled-autoconnect = mkIf cfg.autoConnect {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          # The service still orders after sops-install-secrets.service; this only keeps the
          # autoconnect attempt out of graphical.target's critical path.
          OnBootSec = "30s";
          Unit = "tailscaled-autoconnect.service";
        };
      };
    };

    assertions = [
      {
        assertion = !isSubnetRouter || cfg.advertiseRoutes != [ ];
        message = "Tailscale roles `subnet-router` and `router-exit-node` require `dot.networking.tailscale.advertiseRoutes` to be non-empty.";
      }
      {
        assertion = !(config.dot.networking.vpn.enable && isExitNode);
        message = "Mullvad VPN and Tailscale exit-node advertising both manage default-route behavior. Set either `dot.networking.vpn.enable = false` or use a non-exit-node Tailscale role.";
      }
    ];

    warnings =
      optionals (config.dot.networking.vpn.enable && cfg.acceptRoutes == true) [
        "Mullvad VPN is enabled while `dot.networking.tailscale.acceptRoutes = true`; accepted Tailscale routes may override Mullvad routing."
      ]
      ++ optionals (config.dot.networking.vpn.enable && cfg.acceptDns == true) [
        "Mullvad VPN is enabled while `dot.networking.tailscale.acceptDns = true`; Tailscale DNS may conflict with Mullvad DNS leak protection."
      ];
  };
}
