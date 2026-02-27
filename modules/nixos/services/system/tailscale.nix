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
  cfg = config.my.tailscale;
  isWorkstation = config.my.machine.type == "workstation";
in {
  options.my.services.tailscale = {
    enable = mkEnableOption "Enable Tailscale";
    defaultFlags = mkOption {
      type = listOf str;
      default = ["--ssh"];
      description = ''
        A list of command-line flags that will be passed to the Tailscale daemon on startup
        using the {option}`config.services.tailscale.extraUpFlags`.
        If `isServer` is set to true, the server-specific values will be appended to the list
        defined in this option.
      '';
    };
    isClient = mkOption {
      type = bool;
      default = cfg.enable;
      example = true;
      description = ''
        Whether the target host should utilize Tailscale client features";
        This option is mutually exclusive with {option}`tailscale.isServer` as they both
        configure Taiscale, but with different flags
      '';
    };

    isServer = mkOption {
      type = bool;
      default = !cfg.isClient;
      example = true;
      description = ''
        Whether the target host should utilize Tailscale server features.
        This option is mutually exclusive with {option}`tailscale.isClient` as they both
        configure Taiscale, but with different flags
      '';
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; lib.optionals isWorkstation [trayscale];

    networking.firewall = {
      # always allow traffic from your Tailscale network
      trustedInterfaces = ["${tailscale.interfaceName}"];
      checkReversePath = "loose";

      # allow the Tailscale UDP port through the firewall
      allowedUDPPorts = [tailscale.port];
    };

    services.tailscale = {
      enable = true;
      extraUpFlags =
        cfg.defaultFlags
        ++ optionals cfg.advertiseExitNode [
          "--advertise-exit-node"
          "--operator=${my.name}"
        ];
      extraSetFlags =
        cfg.defaultFlags
        ++ optionals cfg.advertiseExitNode [
          "--advertise-exit-node"
          "--operator=${my.name}"
        ];
      # Enable caddy to acquire certificates from the tailscale daemon
      # - https://tailscale.com/blog/caddy
      permitCertUid = mkIf my.caddy.enable "caddy";
      openFirewall = true;
      useRoutingFeatures = mkDefault "both";
    };

    # server can't be client and client be server
    assertions = [
      (mkIf (cfg.isClient == cfg.isServer) {
        assertion = false;
        message = ''
          You have enabled both client and server features of the Tailscale service. Unless you are providing your own UpFlags, this is probably not what you want.
        '';
      })
    ];
  };
}
