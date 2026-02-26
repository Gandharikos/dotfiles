{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.my.desktop.polkit;
in {
  config = mkIf (cfg == "hyprpolkit") {
    systemd.user.services."polkit-hyprpolkitagent" = {
      # It is required for GUI applications to be able to request elevated privileges.
      Unit = {
        Description = "Hyprland Polkit authentication agent";
        Documentation = "https://wiki.hyprland.org/Hypr-Ecosystem/hyprpolkitagent/";
        PartOf = ["wayland-session@Hyprland.target"];
      };
      Service = {
        ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
        Restart = "always";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
      Install.WantedBy = ["wayland-session@Hyprland.target"];
    };
  };
}
