{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.my.desktop.polkit;
in {
  config = mkIf (cfg == "pantheon") {
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
