{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.my.networking.proxy;
  inherit (lib.modules) mkIf;
  guiEnabled = config.my.gui.enable;
  configFile = config.sops.secrets.proxy_config.path;
in
{
  config = mkIf (cfg.enable && cfg.backend == "mihomo") (
    lib.mkMerge [
      # GUI mode: use Clash Verge
      (mkIf guiEnabled {
        programs.clash-verge = {
          enable = true;
          inherit (cfg) autoStart;
          serviceMode = false; # Full GUI mode
          tunMode = true;
        };
      })

      # Non-GUI mode: use mihomo core
      (mkIf (!guiEnabled) {
        services.mihomo = {
          enable = true;
          webui = pkgs.metacubexd;
          tunMode = true;
          inherit configFile;
        };

        networking.firewall.allowedTCPPorts = [ 9090 ]; # WebUI

        systemd.services.mihomo = {
          after = [ "sops-nix.service" ];
          wants = [ "sops-nix.service" ];
          wantedBy = if cfg.autoStart then [ "multi-user.target" ] else lib.mkForce [ ];
        };
      })
    ]
  );
}
