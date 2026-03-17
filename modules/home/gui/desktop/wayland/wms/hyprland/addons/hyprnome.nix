{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf mkAfter;
  inherit (lib.meta) getExe;
  inherit (lib.my) uwsmApp;
  cfg = config.my.gui.desktop.hyprland;
  hyprnome' = getExe pkgs.hyprnome;
  hyprnomeCmd = args: uwsmApp pkgs hyprnome' args;
in
{
  options.my.gui.desktop.hyprland.nome = {
    enable = mkEnableOption "hyprnome" // {
      default = cfg.enable;
    };
  };
  config = mkIf cfg.nome.enable {
    wayland.windowManager.hyprland.settings.bindd = mkAfter [
      "$mod, mouse_down, Previous Workspace, exec, ${hyprnomeCmd [ "--previous" ]}"
      "$mod, mouse_up, Next Workspace, exec, ${hyprnomeCmd [ ]}"
      "$mod, bracketleft, Previous Workspace, exec, ${hyprnomeCmd [ "--previous" ]}"
      "$mod, bracketright, Next Workspace, exec, ${hyprnomeCmd [ ]}"
      "$mod SHIFT, bracketleft, Move Window to Previous Workspace, exec, ${
        hyprnomeCmd [
          "--previous"
          "--move"
        ]
      }"
      "$mod SHIFT, bracketright, Move Window to Next Workspace, exec, ${hyprnomeCmd [ "--move" ]}"
    ];
  };
}
