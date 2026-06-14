{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.gui.apps.cloudflare-warp;
  enable = osConfig.dot.gui.enable && cfg.enable;
in
{
  options.my.gui.apps.cloudflare-warp = {
    enable = mkEnableOption "Cloudflare Warp" // {
      default = false;
      # osConfig.dot.device.type == "laptop"
      # && pkgs.stdenv.hostPlatform.isLinux;
    };
  };

  config = mkIf enable {
    systemd.user.services = {
      warp-taskbar = {
        Unit = {
          Description = "Cloudflare Warp taskbar";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${pkgs.cloudflare-warp}/bin/warp-taskbar";
          ExecStop = "pkill warp-taskbar";
        };

        Install.WantedBy = [ "graphical-session.target" ];
      };
    };

    home = {
      packages = with pkgs; [ cloudflare-warp ];
    };
  };
}
