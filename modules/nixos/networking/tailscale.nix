{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config) dot;
  inherit (lib.modules) mkIf mkDefault mkBefore;
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
in
{
  config = mkIf cfg.enable {
    sops.secrets = mkIf cfg.autoConnect {
      tailscale_authKey = { };
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
        ++ optionals isClient [
          "--accept-routes"
        ]
        ++ optionals isExitNode [
          "--advertise-exit-node"
        ]
        ++ advertiseRoutesFlag
        ++ optionals isRoutingServer [
          "--operator=${dot.name}"
        ];

      # Modern NixOS prefers declarative state management via extraSetFlags over extraUpFlags
      extraSetFlags =
        cfg.defaultFlags
        ++ optionals isClient [
          "--accept-routes"
        ]
        ++ optionals isExitNode [
          "--advertise-exit-node"
        ]
        ++ advertiseRoutesFlag
        ++ optionals isRoutingServer [
          "--operator=${dot.name}"
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
          after = [ "sops-nix.service" ];
          wants = [ "sops-nix.service" ];
          serviceConfig = {
            # Global systemd defaults are 15s on this host, which is too short when Wi-Fi
            # brings up the default route after tailscaled has already started.
            TimeoutStartSec = "2min";
          };
        };
      };
    };

    assertions = [
      {
        assertion = !isSubnetRouter || cfg.advertiseRoutes != [ ];
        message = "Tailscale roles `subnet-router` and `router-exit-node` require `dot.networking.tailscale.advertiseRoutes` to be non-empty.";
      }
    ];
  };
}
