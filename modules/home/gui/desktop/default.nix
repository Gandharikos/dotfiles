{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.my) scanPaths;
  inherit (lib.options) mkOption;
  inherit (lib.types) int str;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  inherit (config.my.gui) desktop;
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
