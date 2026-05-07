{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.dot) scanPaths;
  inherit (lib.options) mkOption;
  inherit (lib.types) int str;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  inherit (config.dot.gui) desktop;
in
{
  imports = scanPaths ./.;

  options.dot.gui.desktop = {
    workspace = {
      number = mkOption {
        type = int;
        default = 10;
        description = "Number of workspaces";
      };
    };
    modKey = mkOption {
      type = str;
      default =
        if isDarwin then
          "cmd-alt-ctrl"
        else if desktop.default == "niri" then
          "Mod"
        else
          "SUPER";
      internal = true;
      readOnly = true;
      description = ''
        Main modifier key for desktop keybinds.
        - Linux/Niri: Mod
        - Linux/other: SUPER
        - macOS: cmd-alt-ctrl (Hyper key combination)
      '';
    };
  };
}
