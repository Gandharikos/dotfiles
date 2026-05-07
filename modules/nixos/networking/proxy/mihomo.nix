{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.dot.networking.proxy;
  inherit (lib.modules) mkIf;
  configFile = config.sops.secrets.proxy_config.path;
in
{
  # Always run mihomo core as a system service when enabled
  # GUI frontend (Clash Verge) is managed by Home Manager in modules/home/gui/apps/clash-verge.nix
  config = mkIf (cfg.enable && cfg.backend == "mihomo") {
    services.mihomo = {
      enable = true;
      webui = pkgs.metacubexd;
      tunMode = true;
      inherit configFile;
    };

    # Allow access to mihomo API and WebUI
    networking.firewall.allowedTCPPorts = [
      9090 # External controller (API)
      9091 # WebUI (metacubexd)
    ];

    systemd.services.mihomo = {
      after = [ "sops-nix.service" ];
      wants = [ "sops-nix.service" ];
      wantedBy = if cfg.autoStart then [ "multi-user.target" ] else lib.mkForce [ ];
    };
  };
}
