{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.my.desktop.polkit;
in {
  config = mkIf (cfg == "mate") {
    systemd.user.services.polkit-mate-authentication-agent-1 = {
      Unit.Description = "MATE PolicyKit agent";

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.mate.mate-polkit}/libexec/polkit-mate-authentication-agent-1";
        Restart = "on-failure";
        TimeoutStopSec = 10;
        RestartSec = 1;
      };

      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
