{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.my.gui.desktop.niri;
in {
  config = mkIf cfg.enable {
    programs.niri.settings.environment = {
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_DESKTOP = "niri";
    };
  };
}
