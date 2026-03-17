{ lib, ... }:
let
  inherit (lib.my) scanPaths;
  inherit (lib.options) mkOption;
  inherit (lib.types) enum;
in
{
  imports = scanPaths ./.;
  options.my.gui.desktop = {
    mainKey = mkOption {
      type = enum [
        "SUPER"
        "CTRL"
        "ALT"
      ];
      default = "SUPER";
      description = "Main modifier key for desktop keybinds.";

    };
  };
}
