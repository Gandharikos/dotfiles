{ lib, ... }:
let
  inherit (lib.my) scanPaths;
  inherit (lib.options) mkOption;
  inherit (lib.types) int;
in
{
  imports = scanPaths ./.;

  options.my.gui.desktop = {
    workspace = {
      number = mkOption {
        type = int;
        default = 10;
        description = "Number of workspaces";
      };
    };
  };
}
