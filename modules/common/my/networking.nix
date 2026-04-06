{ lib, ... }:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) enum listOf str;
in
{
  options.my.networking = {
    proxy = {
      enable = mkEnableOption "proxy service (Clash Verge with mihomo core)" // {
        default = true;
      };

      autoStart = mkEnableOption "auto start proxy on boot" // {
        default = false;
      };
    };

    tailscale = {
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
  };
}
