{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config) my;
  inherit (lib.modules) mkIf mkDefault mkBefore;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) enum listOf str;
  inherit (lib.lists) optionals;
  inherit (lib.strings) concatStringsSep;

  cfg = config.my.services.tailscale;
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
  options.my.services.tailscale = {
    enable = mkEnableOption "Enable Tailscale" // {
      default = true;
    };

    autoConnect = mkEnableOption "Automatically connect to Tailscale";

    defaultFlags = mkOption {
      type = listOf str;
      default = [ "--ssh" ];
      description = "Default command-line flags passed to Tailscale before role-specific flags.";
    };

    role = mkOption {
      type = enum [
        "client"
        "subnet-router"
        "exit-node"
        "router-exit-node"
      ];
      default = "client";
      description = ''
        High-level Tailscale role for this host.
        `subnet-router` and `router-exit-node` require `advertiseRoutes` to be set.
      '';
    };

    advertiseRoutes = mkOption {
      type = listOf str;
      default = [ ];
      example = [
        "192.168.1.0/24"
        "10.0.0.0/24"
      ];
      description = ''
        Subnets advertised by Tailscale when the role includes subnet routing.
      '';
    };
  };

  config = mkIf cfg.enable {
    sops.secrets = mkIf cfg.autoConnect {
      tailscale_authKey = { };
    };

    environment.systemPackages = with pkgs; [ tailscale ];
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
          "--operator=${my.name}"
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
          "--operator=${my.name}"
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
        };
      };
    };

    assertions = [
      {
        assertion = !isSubnetRouter || cfg.advertiseRoutes != [ ];
        message = "Tailscale roles `subnet-router` and `router-exit-node` require `my.services.tailscale.advertiseRoutes` to be non-empty.";
      }
    ];
  };
}
