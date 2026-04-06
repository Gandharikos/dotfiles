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
  configFile = "/var/lib/mihomo/config.yaml";
  isServiceMode = cfg.mode == "service";
  isDesktopMode = cfg.mode == "desktop";
in
{
  config = mkIf (cfg.enable && cfg.backend == "mihomo") {
    sops.secrets.mihomo_config = mkIf isServiceMode {
      sopsFile = "${self}/secrets/services/mihomo.yaml";
      path = configFile;
      owner = "mihomo";
      group = "mihomo";
      mode = "0400";
    };

    # Desktop mode delegates runtime management to Clash Verge itself instead
    # of running a second standalone mihomo service in parallel.
    programs.clash-verge = mkIf isDesktopMode {
      enable = true;
      autoStart = false;
      serviceMode = false;
      tunMode = true;
    };

    # https://wiki.metacubex.one/config
    # https://nixos.wiki/wiki/Mihomo
    services.mihomo = mkIf isServiceMode {
      enable = true;
      webui = mkIf cfg.enableWebui pkgs.metacubexd;
      tunMode = true;
      inherit configFile;
    };

    networking.firewall.allowedTCPPorts = mkIf isServiceMode [ 9090 ];

    systemd.services.mihomo = mkIf isServiceMode {
      after = [ "sops-nix.service" ];
      wants = [ "sops-nix.service" ];
    };
  };
}
