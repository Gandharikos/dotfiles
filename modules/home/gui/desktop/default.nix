{lib, ...}: let
  inherit (lib.my) scanPaths;
  inherit (lib.options) mkOption;
  inherit (lib.types) int enum;
in {
  imports = scanPaths ./.;

  options.my.gui.desktop = {
    workspace = {
      number = mkOption {
        type = int;
        default = 10;
        description = "Number of workspaces";
      };
    };
    mainKey = mkOption {
      type = enum ["SUPER" "CTRL" "ALT"];
      default = "SUPER";
      description = "Main modifier key for desktop keybinds.";
    };
  };
}
