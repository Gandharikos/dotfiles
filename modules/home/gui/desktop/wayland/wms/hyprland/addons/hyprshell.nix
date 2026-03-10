{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf mkAfter;
  inherit (lib.my) withUWSM;
  cfg = config.my.gui.desktop.hyprland;
  hyprshell' = withUWSM pkgs "hyprshell";
in {
  options.my.gui.desktop.hyprland.switch = {
    enable =
      mkEnableOption "hyprswitch"
      // {
        default = cfg.enable;
      };
  };

  config = mkIf cfg.switch.enable {
    home.packages = with pkgs; [
      hyprshell
    ];

    wayland.windowManager.hyprland.settings = {
      exec-once = [
        "${hyprshell'} init --show-title --size-factor 5.5 --workspaces-per-row 5 &"
      ];
      bindd = mkAfter [
        # Switcher
        "ALT, tab, App Switcher Next, exec, ${hyprshell'} gui --mod-key ALT --key tab --close mod-key-release --reverse-key=mod=SHIFT --max-switch-offset 9 -m && ${hyprshell'} dispatch"
        "ALT SHIFT, tab, App Switcher Previous, exec, ${hyprshell'} gui --mod-key ALT --key tab --close mod-key-release --reverse-key=mod=SHIFT --max-switch-offset 9 -m && ${hyprshell'} dispatch -r"
      ];
    };

    xdg.configFile = {
      "hyprshell/style.css".source = ./styles/hyprshell.css;
    };
  };
}
