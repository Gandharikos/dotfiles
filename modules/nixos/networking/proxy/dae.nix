{ lib, config, ... }:
let
  cfg = config.dot.networking.proxy;
in
{
  options.dot.networking.proxy.dae.configFile = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
    description = "Runtime dae configuration path. Keep credentials outside the Nix store.";
  };

  config = lib.mkIf (cfg.enable && cfg.backend == "dae") {
    assertions = [
      {
        assertion = cfg.dae.configFile != null;
        message = "dae requires an explicit runtime dae.configFile; no legacy secret is loaded automatically.";
      }
    ];

    services.dae = {
      enable = true;
      configFile = cfg.dae.configFile;
      # Network exposure is host-owned, not implied by selecting a backend.
      openFirewall.enable = lib.mkDefault false;
    };

    systemd.services.dae = {
      after = [ "sops-install-secrets.service" ];
      wants = [ "sops-install-secrets.service" ];
      wantedBy = if cfg.autoStart then [ "multi-user.target" ] else lib.mkForce [ ];
    };
  };
}
