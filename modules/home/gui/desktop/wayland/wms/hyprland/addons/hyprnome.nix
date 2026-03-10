{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf mkAfter;
  inherit (lib.my) withUWSM;
  cfg = config.my.gui.desktop.hyprland;
  hyprnome' = withUWSM pkgs "hyprnome";
in {
  options.my.gui.desktop.hyprland.nome = {
    enable =
      mkEnableOption "hyprnome"
      // {
        default = cfg.enable;
      };
  };
  config = mkIf cfg.nome.enable {
    home.packages = with pkgs; [
      hyprnome
    ];

    wayland.windowManager.hyprland .settings.bindd = mkAfter [
      "$mod, mouse_down, Previous Workspace, exec, ${hyprnome'} --previous"
      "$mod, mouse_up, Next Workspace, exec, ${hyprnome'}"
      "$mod, bracketleft, Previous Workspace, exec, ${hyprnome'} --previous"
      "$mod, bracketright, Next Workspace, exec, ${hyprnome'}"
      "$mod SHIFT, bracketleft, Move Window to Previous Workspace, exec, ${hyprnome'} --previous --move"
      "$mod SHIFT, bracketright, Move Window to Next Workspace, exec, ${hyprnome'} --move"
    ];
  };
}
