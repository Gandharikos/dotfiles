{lib, ...}: let
  inherit (lib.my) scanPaths;
  inherit (lib.options) mkOption;
  inherit (lib.types) int enum;
in {
  imports = scanPaths ./.;

  options.my.gui.desktop = {
    lock = mkOption {
      type = enum ["hyprlock" "dms"];
      default = "dms";
      description = "The lock screen to use";
    };
    idle = mkOption {
      type = enum ["hypridle"];
      default = "hypridle";
      description = "The idle tool to use";
    };
    shot = mkOption {
      type = enum ["hyprshot" "grimblast" "dms"];
      default = "grimblast";
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
