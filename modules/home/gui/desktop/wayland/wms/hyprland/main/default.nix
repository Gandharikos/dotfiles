{
  lib,
  config,
  ...
}:
let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) listOf enum;
  inherit (lib.modules) mkIf;
  inherit (lib.my) scanPaths;
  inherit (config.my.gui) desktop;
  cfg = desktop.hyprland;
in
{
  imports = scanPaths ./.;

  options.my.gui.desktop.hyprland = {
    enable = mkEnableOption "Enable Hyprland" // {
      default = desktop.wayland.enable && desktop.default == "hyprland";
      internal = true;
      readOnly = true;
    };
    plugins = {
      enable = mkEnableOption "Enable Hyprland plugins" // {
        default = true;
      };
      list = mkOption {
        default = [
          "hyprfocus"
          "hyprsplit"
          "hyprexpo"
          "hyprspace"
          "hyprgrass"
          "hypr-dynamic-cursors"
        ];
        type = listOf (enum [
          "hy3"
          "hyprfocus"
          "hyprsplit"
          "hyprspace"
          "hyprexpo"
          "hyprbars"
          "hyprgrass"
          "hyprtrails"
          "hyprscroller"
          "borders-plus-plus"
          "csgo-vulkan-fix"
          "hypr-dynamic-cursors"
          "hyprwinwrap"
        ]);
        description = "List of Hyprland plugins to enable";
      };
    };
  };

  config = mkIf cfg.enable {
    # enable hyprland
    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      systemd = {
        # NOTE: we use uwsm start hyprland, not manual ssystemd
        enable = false;
        variables = [ "--all" ];
        extraCommands = [
          "systemctl --user stop graphical-session.target"
          "systemctl --user start hyprland-session.target"
        ];
      };
    };

    # make stuff work on wayland
    # home.sessionVariables = {
    #   QT_QPA_PLATFORM = "wayland";
    #   SDL_VIDEODRIVER = "wayland";
    #   XDG_SESSION_TYPE = "wayland";
    # };
  };
}
