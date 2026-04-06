{
  lib,
  config,
  self,
  ...
}:
let
  cfg = config.my.networking.proxy;
  inherit (lib.modules) mkIf;

  # Config paths
  clashVergeConfigDir = "${config.my.home}/.config/clash-verge";
  configFile = "${clashVergeConfigDir}/config.yaml";
in
{
  config = mkIf cfg.enable {
    sops.secrets.clash_config = {
      sopsFile = "${self}/secrets/services/clash.yaml";
      path = configFile;
      owner = config.my.name;
      group = "staff";
      mode = "0600";
    };

    homebrew.casks = [ "clash-verge-rev" ];
  };
}
