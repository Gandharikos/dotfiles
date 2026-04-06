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
in
{
  config = mkIf (cfg.enable && cfg.backend == "mihomo") (
    lib.mkMerge [
      {
        sops.secrets.mihomo_config = {
          sopsFile = "${self}/secrets/services/mihomo.yaml";
          path = configFile;
          owner = "mihomo";
          group = "mihomo";
          mode = "0400";
        };

        # Install the default GUI client when enabled
        environment.systemPackages = lib.optionals cfg.enableGui [ pkgs.clash-verge-rev ];

        # https://wiki.metacubex.one/config
        # https://nixos.wiki/wiki/Mihomo
        services.mihomo = {
          enable = true;
          webui = mkIf cfg.enableWebui pkgs.metacubexd;
          # package = pkgs.mihomo;
          # tunMode = true;
          inherit configFile;
        };

        networking.firewall.allowedTCPPorts = [ 9090 ];

        systemd.services.mihomo = {
          after = [ "sops-nix.service" ];
          wants = [ "sops-nix.service" ];

          # Do not start on boot unless autoStart is enabled
          wantedBy = mkIf (!cfg.autoStart) (lib.mkForce [ ]);
        };
      }
    ]
  );
}
