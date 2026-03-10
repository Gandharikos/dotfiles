{
  lib,
  config,
  osClass,
  ...
}: let
  inherit (lib.my) scanPaths;
  inherit (lib.options) mkOption;
  inherit (lib.types) int enum nullOr;
  inherit (config.my.gui) desktop;
in {
  imports = scanPaths ./.;

  options.my.gui.desktop = {
    lock = mkOption {
      type = nullOr (enum ["hyprlock" "dms"]);
      default =
        if osClass == "nixos" && desktop.enable
        then "dms"
        else null;
      description = "The lock screen to use";
    };
    idle = mkOption {
      type = nullOr (enum ["hypridle"]);
      default =
        if osClass == "nixos" && desktop.enable
        then "hypridle"
        else null;
      description = "The idle tool to use";
    };
    shot = mkOption {
      type = nullOr (enum ["hyprshot" "grimblast" "dms"]);
      default =
        if osClass == "nixos" && desktop.enable
        then "grimblast"
        else null;
      description = "The screenshot tool to use";
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
