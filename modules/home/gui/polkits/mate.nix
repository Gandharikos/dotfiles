{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (config.my) gui;
  cfg = config.my.gui.desktop.polkit;
in {
  config = mkIf (isLinux && gui.enable && cfg == "mate") {
    systemd.user.services.polkit-mate-authentication-agent-1 = {
      Unit.Description = "MATE PolicyKit agent";

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.mate-polkit}/libexec/polkit-mate-authentication-agent-1";
        Restart = "on-failure";
        TimeoutStopSec = 10;
        RestartSec = 1;
      };

      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
