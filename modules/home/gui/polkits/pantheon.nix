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
  config = mkIf (isLinux && gui.enable && cfg == "pantheon") {
    systemd.user.services.polkit-pantheon-authentication-agent-1 = {
      Unit.Description = "Pantheon PolicyKit agent";

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.pantheon.pantheon-agent-polkit}/libexec/policykit-1-pantheon/io.elementary.desktop.agent-polkit";
        Restart = "on-failure";
        TimeoutStopSec = 10;
        RestartSec = 1;
      };

      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
