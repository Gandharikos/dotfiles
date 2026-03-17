{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf mkAfter;
  inherit (lib.meta) getExe;
  inherit (lib.my) uwsmScript;
  cfg = config.my.gui.desktop.hyprland;
  hyprshell' = getExe pkgs.hyprshell;
  hyprshellInit = uwsmScript pkgs "hyprshell-init" ''
    exec ${hyprshell'} init --show-title --size-factor 5.5 --workspaces-per-row 5
  '';
  hyprshellGuiNext = uwsmScript pkgs "hyprshell-gui-next" ''
    ${hyprshell'} gui --mod-key ALT --key tab --close mod-key-release --reverse-key=mod=SHIFT --max-switch-offset 9 -m
    ${hyprshell'} dispatch
  '';
  hyprshellGuiPrev = uwsmScript pkgs "hyprshell-gui-prev" ''
    ${hyprshell'} gui --mod-key ALT --key tab --close mod-key-release --reverse-key=mod=SHIFT --max-switch-offset 9 -m
    ${hyprshell'} dispatch -r
  '';
in
{
  options.my.gui.desktop.hyprland.switch = {
    enable = mkEnableOption "hyprswitch" // {
      default = cfg.enable;
    };
  };

  config = mkIf cfg.switch.enable {
    wayland.windowManager.hyprland.settings = {
      exec-once = [
        hyprshellInit
      ];
      bindd = mkAfter [
        # Switcher
        "ALT, tab, App Switcher Next, exec, ${hyprshellGuiNext}"
        "ALT SHIFT, tab, App Switcher Previous, exec, ${hyprshellGuiPrev}"
      ];
    };

    xdg.configFile = {
      "hyprshell/style.css".source = ./styles/hyprshell.css;
    };
  };
}
