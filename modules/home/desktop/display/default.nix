{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.my) scanPaths ldTernary;
  inherit (lib.options) mkOption;
  inherit (lib.types) int enum nullOr;
  inherit (config.my) desktop;
in {
  imports = scanPaths ./.;

  options.my.desktop = {
    shell = mkOption {
      type = nullOr (enum ["DankMaterialShell" "NoctaliaShell" "CaelestiaShell"]);
      default =
        ldTernary pkgs
        (
          if desktop.enable
          then "DankMaterialShell"
          else null
        )
        null;
      description = "The desktop shell to use";
    };
    lock = mkOption {
      type = nullOr (enum ["hyprlock"]);
      default =
        ldTernary pkgs
        (
          if desktop.enable
          then "hyprlock"
          else null
        )
        null;
      description = "The lock screen to use";
    };
    wallEngine = mkOption {
      type = nullOr (enum ["hyprpaper"]);
      default =
        ldTernary pkgs
        (
          if desktop.enable
          then "hyprpaper"
          else null
        )
        null;
      description = "The wallpaper engine to use";
    };
    idle = mkOption {
      type = nullOr (enum ["hypridle"]);
      default =
        ldTernary pkgs
        (
          if desktop.enable
          then "hypridle"
          else null
        )
        null;
      description = "The idle screen to use";
    };
    shot = mkOption {
      type = nullOr (enum ["hyprshot" "grimblast"]);
      default =
        ldTernary pkgs
        (
          if desktop.enable
          then "grimblast"
          else null
        )
        null;
      description = "The screenshot tool to use";
    };
    notification = mkOption {
      type = nullOr (enum ["avizo"]);
      default =
        ldTernary pkgs
        (
          if desktop.enable
          then "avizo"
          else null
        )
        null;
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
