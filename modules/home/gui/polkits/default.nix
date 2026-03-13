{
  lib,
  config,
  ...
}: let
  inherit (lib.my) scanPaths;
  inherit (lib.options) mkOption;
  inherit (lib.types) enum;
  inherit (config.my.gui) desktop;
in {
  imports = scanPaths ./.;
  options.my.gui.desktop.polkit = mkOption {
    type = enum ["pantheon" "hyprpolkit" "mate"];
    default =
      if desktop.hyprland.enable
      then "hyprpolkit"
      else if desktop.default == "niri"
      then "mate"
      else "pantheon";
    description = ''
      The policy kit agent to use for authentication.
      This is the GUI that pops up when you need to enter a password for
      administrative tasks.
    '';
  };
}
