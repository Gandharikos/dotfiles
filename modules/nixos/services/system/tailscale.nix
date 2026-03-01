{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) my;
  inherit (lib.modules) mkIf mkDefault;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) bool listOf str;
  inherit (lib.lists) optionals;
  inherit (config.services) tailscale;

  cfg = config.my.services.tailscale;
  isWorkstation = config.my.machine.type == "workstation";
in {
  options.my.services.tailscale = {
    enable = mkEnableOption "Enable Tailscale";

    defaultFlags = mkOption {
      type = listOf str;
      default = ["--ssh"];
      description = "Default command-line flags passed to the Tailscale daemon.";
    };

    # Fix: Added the previously missing option used in the config block
    advertiseExitNode = mkOption {
      type = bool;
      default = cfg.isServer; # Default to true if it's a server, but can be manually overridden
      description = "Advertise this machine as a Tailscale exit node.";
    };

    isClient = mkOption {
      type = bool;
      default = cfg.enable && !cfg.isServer;
      description = "Whether the target host should utilize Tailscale client features.";
    };

    isServer = mkOption {
      type = bool;
      default = false; # Disabled by default; must be explicitly enabled in host-specific configs
      description = "Whether the target host should utilize Tailscale server features.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; lib.optionals isWorkstation [trayscale];

    networking.firewall = {
      # Always allow all traffic from the Tailscale virtual interface
      trustedInterfaces = ["${tailscale.interfaceName}"];

      # Loose reverse path filtering is strictly required for Exit Nodes and Subnet Routers
      checkReversePath = "loose";
    };

    services.tailscale = {
      enable = true;

      # Setting this to true automatically handles opening the required UDP ports
      openFirewall = true;

      # Apply specific flags based on the logical role (Server vs Client)
      extraUpFlags =
        cfg.defaultFlags
        ++ optionals cfg.advertiseExitNode [
          "--advertise-exit-node"
        ]
        ++ optionals cfg.isServer [
          # Additional server-specific flags (e.g., subnet routing) can be appended here
          "--operator=${my.name}"
        ]
        ++ optionals cfg.isClient [
          # Clients typically need to accept routes pushed by the Tailscale server/subnet routers
          "--accept-routes"
        ];

      # Modern NixOS prefers declarative state management via extraSetFlags over extraUpFlags
      extraSetFlags =
        cfg.defaultFlags
        ++ optionals cfg.advertiseExitNode [
          "--advertise-exit-node"
        ];

      # Graceful integration with Caddy to acquire certificates from the tailscale daemon
      # - https://tailscale.com/blog/caddy
      permitCertUid = mkIf (config.my.caddy.enable or false) "caddy";

      useRoutingFeatures = mkDefault "both";
    };

    assertions = [
      {
        assertion = !(cfg.isClient && cfg.isServer);
        message = "Tailscale service cannot act as both client and server strictly at the same time in this module's logic.";
      }
    ];
  };
}
