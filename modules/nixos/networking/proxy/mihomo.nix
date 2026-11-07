{
  lib,
  config,
  ...
}:
let
  cfg = config.dot.networking.proxy;
  inherit (lib.modules) mkIf;
  configFile =
    if cfg.mihomo.configFile != null then
      cfg.mihomo.configFile
    else
      config.sops.secrets.proxy_config.path;
in
{
  # This backend is headless; Clash Verge is a separate backend.
  config = mkIf (cfg.enable && cfg.backend == "mihomo") {
    services.mihomo = {
      enable = true;
      tunMode = true;
      inherit configFile;
    };

    systemd.services.mihomo = {
      after = [ "sops-install-secrets.service" ];
      wants = [ "sops-install-secrets.service" ];
      wantedBy = if cfg.autoStart then [ "multi-user.target" ] else lib.mkForce [ ];
    };
  };
}
