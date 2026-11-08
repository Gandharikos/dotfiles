{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.networking.proxy.dae;
in
{
  options.dot.networking.proxy.dae = {
    enable = lib.mkEnableOption "independent dae transparent proxy, optionally paired with mihomo or sing-box";
    autoStart = lib.mkEnableOption "dae auto start on boot, independently of the main proxy";
    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/run/secrets/dae-config";
      description = "Runtime native dae configuration, normally decrypted by SOPS. Do not embed subscription credentials in Nix.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.configFile != null;
        message = "Enabling dae requires dot.networking.proxy.dae.configFile; provide a runtime native .dae configuration.";
      }
      {
        assertion = config.services.dae.config == null;
        message = "Use dae.configFile instead of services.dae.config to keep credentials out of the Nix store.";
      }
    ];

    services.dae = {
      enable = true;
      inherit (cfg) configFile;
      # The upstream module otherwise exposes its TPROXY port on every interface.
      openFirewall.enable = lib.mkDefault false;
    };

    systemd.services.dae = {
      after = [
        "network-online.target"
        "sops-install-secrets.service"
      ];
      wants = [
        "network-online.target"
        "sops-install-secrets.service"
      ];
      wantedBy = lib.mkForce (lib.optionals cfg.autoStart [ "multi-user.target" ]);
    };
  };
}
