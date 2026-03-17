{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.my.gui.login.sddm) enable;
in
{
  config = mkIf enable {
    services.displayManager.sddm = {
      enable = true;
      package = pkgs.kdePackages.sddm; # allow qt6 themes to work
      wayland.enable = true; # run under wayland rarther than X11
      settings.General.InputMethod = "";
    };
  };
}
