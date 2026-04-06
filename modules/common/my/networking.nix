{ lib, ... }:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) enum listOf str;
in
{
  options.my.networking = {
    proxy = {
      enable = mkEnableOption "proxy service";

      backend = mkOption {
        type = enum [ "mihomo" ];
        default = "mihomo";
        description = "Proxy backend to use (currently only mihomo is supported)";
      };

      enableWebui = mkEnableOption "proxy web UI" // {
        default = true;
      };

      autoStart = mkEnableOption "auto start proxy service on boot" // {
        default = false;
      };

      enableGui = mkEnableOption "Clash Verge GUI client" // {
        default = true;
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
