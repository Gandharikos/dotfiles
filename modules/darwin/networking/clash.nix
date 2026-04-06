{
  lib,
  config,
  self,
  ...
}:
let
  cfg = config.my.networking.proxy;
  inherit (lib.modules) mkIf;

  # Clash Verge config directory
  configDir = "${config.my.home}/.config/clash-verge";
  configFile = "${configDir}/config.yaml";
in
{
  config = mkIf cfg.enable {
    # Install Clash Verge via Homebrew
    # Works in both GUI and service modes
    # Service mode: configure in Clash Verge settings (enable "Service Mode")
    homebrew.casks = [ "clash-verge-rev" ];

    # Decrypt clash config to clash-verge config directory
    # sops.secrets automatically creates parent directory with proper permissions
    sops.secrets.clash_config = {
      sopsFile = "${self}/secrets/services/clash.yaml";
      path = configFile;
      owner = config.my.name;
      group = "staff";
      mode = "0600";
    };

    # Note: On Darwin, Clash Verge manages its own service
    # To enable service mode (when my.gui.enable = false):
    # 1. Open Clash Verge
    # 2. Settings -> General -> Enable "Service Mode"
    # 3. (Optional) Enable "Launch on Startup" if autoStart is desired
  };
}
