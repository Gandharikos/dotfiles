{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.my) scanPaths;
  inherit (lib.options) mkOption;
  inherit (lib.types) int str;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
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
    mod = mkOption {
      type = str;
      default = if isDarwin then "cmd-alt-ctrl" else "SUPER";
      description = ''
        Main modifier key for desktop keybinds.
        - Linux: SUPER (Windows/Super key), CTRL, or ALT
        - macOS: cmd-alt-ctrl (Hyper key combination)
      '';
    };
  };
}
