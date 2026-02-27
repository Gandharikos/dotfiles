{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.my.desktop.hyprland;
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      general.layout = "dwindle";

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master = {
        # no_gaps_when_only = true;
        new_on_top = true;
        new_status = "master";
        mfact = 0.55;
        special_scale_factor = 1;
      };
    };
  };
}
