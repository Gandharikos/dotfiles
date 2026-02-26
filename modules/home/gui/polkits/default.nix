{
  lib,
  config,
  ...
}: let
  inherit (lib.my) scanPaths isHyprland;
  inherit (lib.options) mkOption;
  inherit (lib.types) enum;
in {
  imports = scanPaths ./.;
  options.my.desktop.polkit = mkOption {
    type = enum ["pantheon" "hyprpolkit" "mate"];
    default =
      if isHyprland config
      then "hyprpolkit"
      else if config.my.desktop.default == "niri"
      then "mate"
      else "pantheon";
    description = ''
      The policy kit agent to use for authentication.
      This is the GUI that pops up when you need to enter a password for
      administrative tasks.
    '';
  };
}
