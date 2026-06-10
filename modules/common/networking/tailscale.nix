{ lib, ... }:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types)
    bool
    enum
    listOf
    str
    ;
in
{
  options.dot.networking.tailscale = {
    enable = mkEnableOption "Enable Tailscale" // {
      default = true;
    };

    autoConnect = mkEnableOption "Automatically connect to Tailscale" // {
      default = true;
    };

    defaultFlags = mkOption {
      type = listOf str;
      default = [ "--ssh" ];
      description = "Default command-line flags passed to Tailscale before role-specific flags.";
    };

    acceptRoutes = mkOption {
      type = bool;
      default = true;
      description = "Whether to accept routes advertised by other Tailscale nodes.";
    };

    acceptDns = mkOption {
      type = bool;
      default = true;
      description = "Whether to accept DNS configuration from the Tailscale admin panel.";
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
}
