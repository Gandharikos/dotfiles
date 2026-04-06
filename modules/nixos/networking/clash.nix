{
  lib,
  config,
  pkgs,
  self,
  ...
}:
let
  cfg = config.my.networking.proxy;
  inherit (lib.modules) mkIf;
  guiEnabled = config.my.gui.enable;

  # Config paths
  clashVergeConfigDir = "${config.my.home}/.config/clash-verge";
  mihomoConfigFile = "/var/lib/mihomo/config.yaml";
  configFile = if guiEnabled then "${clashVergeConfigDir}/config.yaml" else mihomoConfigFile;
in
{
  config = mkIf cfg.enable (
    lib.mkMerge [
      # Common: decrypt secrets
      {
        sops.secrets.clash_config = {
          sopsFile = "${self}/secrets/services/clash.yaml";
          path = configFile;
          owner = if guiEnabled then config.my.name else "mihomo";
          group = if guiEnabled then "users" else "mihomo";
          mode = if guiEnabled then "0600" else "0400";
        };
      }

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
          configFile = mihomoConfigFile;
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
