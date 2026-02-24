{
  lib,
  config,
  ...
}: let
  cfg = config.my.services.proxy;
  inherit (lib.modules) mkIf;
in {
  # This module is only valid on Linux systems.
  config = mkIf cfg.enable {
    services.dae = {
      enable = true;
      config = {
        nodes = [
          {
            name = "mihomo-upstream";
            type = "socks";
            addr = "socks5://127.0.0.1:7890/";
          }
        ];
        routing = [
          {
            default = "mihomo-upstream";
          }
        ];
      };
    };

    # Do not start on boot; let the dispatcher script control it.
    systemd.services.dae.wantedBy = lib.mkForce [];
  };
}
