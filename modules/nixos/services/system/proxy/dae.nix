{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.my.services.proxy;
  inherit (lib.modules) mkIf;
  daeBin = lib.getExe pkgs.dae;
  daeAssets = pkgs.symlinkJoin {
    name = "dae-assets";
    paths = with pkgs; [
      v2ray-geoip
      v2ray-domain-list-community
    ];
  };
  daeConfig = pkgs.writeText "config.dae" ''
    node {
      name: "mihomo-upstream"
      type: socks
      addr: "socks5://127.0.0.1:7890/"
    }

    routing {
      default: "mihomo-upstream"
    }
  '';
in
{
  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.dae ];
    systemd.packages = [ pkgs.dae ];

    networking.firewall.allowedTCPPorts = [ 12345 ];
    networking.firewall.allowedUDPPorts = [ 12345 ];

    # Avoid the upstream services.dae module because its eval-time assertion
    # realizes dae-assets, which breaks evaluating x86_64-linux hosts from Darwin.
    systemd.services.dae = {
      wantedBy = lib.mkForce [ ];
      serviceConfig = {
        LoadCredential = [ "config.dae:${daeConfig}" ];
        ExecStartPre = [
          ""
          "${daeBin} validate -c \${CREDENTIALS_DIRECTORY}/config.dae"
        ];
        ExecStart = [
          ""
          "${daeBin} run --disable-timestamp -c \${CREDENTIALS_DIRECTORY}/config.dae"
        ];
        Environment = "DAE_LOCATION_ASSET=${daeAssets}/share/v2ray";
      };
    };
  };
}
