{
  lib,
  config,
  osClass,
  ...
}: let
  inherit (lib.my) scanPaths;
  inherit (lib.options) mkOption;
  inherit (lib.types) int enum nullOr;
  inherit (config.my) desktop;
in {
  imports = scanPaths ./.;

  options.my.desktop = {
    lock = mkOption {
      type = nullOr (enum ["hyprlock"]);
      default =
        if osClass == "nixos" && desktop.enable
        then "hyprlock"
        else null;
      description = "The lock screen to use";
    };
    wallEngine = mkOption {
      type = nullOr (enum ["hyprpaper"]);
      default =
        if osClass == "nixos" && desktop.enable
        then "hyprpaper"
        else null;
      description = "The wallpaper engine to use";
    };
    idle = mkOption {
      type = nullOr (enum ["hypridle"]);
      default =
        if osClass == "nixos" && desktop.enable
        then "hypridle"
        else null;
      description = "The idle screen to use";
    };
    shot = mkOption {
      type = nullOr (enum ["hyprshot" "grimblast"]);
      default =
        if osClass == "nixos" && desktop.enable
        then "grimblast"
        else null;
      description = "The screenshot tool to use";
    };
    notification = mkOption {
      type = nullOr (enum ["avizo"]);
      default =
        if osClass == "nixos" && desktop.enable
        then "avizo"
        else null;
      description = "The notification daemon to use";
    };
    general = {
      workspace = {
        number = mkOption {
          type = int;
          default = 10;
          description = "Number of workspaces";
        };
      };
      keybind = {
        modifier = mkOption {
          type = enum ["SUPER" "CTRL" "ALT"];
          default = "SUPER";
          description = "Modifier key for keybinds";
        };
      };
    };
  };
}
