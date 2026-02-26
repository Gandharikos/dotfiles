{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.my.desktop.login;
in {
  config = mkIf (cfg == "sddm") {
    services.displayManager.sddm = {
      enable = true;
      package = pkgs.kdePackages.sddm; # allow qt6 themes to work
      wayland.enable = true; # run under wayland rarther than X11
      settings.General.InputMethod = "";
    };
  };
}
