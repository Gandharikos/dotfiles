{
  lib,
  config,
  ...
}: let
  inherit (lib.my) scanPaths;
  inherit (lib.options) mkOption;
  inherit (lib.types) int enum str;
  inherit (config.xdg.userDirs.extraConfig) SCREENSHOTS;
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
      screenshot = {
        path = mkOption {
          type = str;
          default = "${SCREENSHOTS}/screenshot-%Y%m%d-%H%M%S.png";
          description = "Default output path template for desktop screenshots.";
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
