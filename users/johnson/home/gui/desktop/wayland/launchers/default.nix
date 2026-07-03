{ lib, ... }:
let
  inherit (lib.dot) scanPaths;
  inherit (lib.options) mkOption;
  inherit (lib.types) enum;
in
{
  imports = scanPaths ./.;

  options.my.gui.desktop.launcher = {
    default = mkOption {
      type = enum [
        "shell"
        "vicinae"
      ];
      default = "vicinae";
      description = "The desktop launcher to use.";
    };
  };
}
