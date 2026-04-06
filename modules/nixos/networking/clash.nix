{
  lib,
  config,
  self,
  ...
}:
let
  cfg = config.my.networking.proxy;
  inherit (lib.modules) mkIf;
  guiEnabled = config.my.gui.enable;

  # Clash Verge config directory (user-specific)
  configDir = "${config.my.home}/.config/clash-verge";
  configFile = "${configDir}/config.yaml";
in
{
  config = mkIf cfg.enable {
    # Decrypt clash config to clash-verge config directory
    sops.secrets.clash_config = {
      sopsFile = "${self}/secrets/services/clash.yaml";
      path = configFile;
      owner = config.my.name;
      group = "users";
      mode = "0600";
    };

    # Clash Verge works in both GUI and service modes
    # When my.gui.enable = false, it runs as a headless service
    programs.clash-verge = {
      enable = true;
      inherit (cfg) autoStart;
      serviceMode = !guiEnabled;
      tunMode = true;
    };
  };
}
