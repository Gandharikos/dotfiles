{ lib, ... }:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) enum listOf str;
in
{
  options.my.networking = {
    proxy = {
      enable = mkEnableOption "proxy service" // {
        default = true;
      };

      backend = mkOption {
        type = enum [ "mihomo" ];
        default = "mihomo";
        description = "Proxy backend to use (currently only mihomo is supported)";
      };

      mode = mkOption {
        type = enum [
          "service"
          "desktop"
        ];
        default = "service";
        description = ''
          Proxy operating mode.
          `service` runs Mihomo as a standalone service.
          `desktop` uses the Clash Verge desktop workflow instead.
        '';
      };

      enableWebui = mkEnableOption "proxy web UI" // {
        default = true;
      };

      autoStart = mkEnableOption "auto start proxy service on boot on Darwin in service mode" // {
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
