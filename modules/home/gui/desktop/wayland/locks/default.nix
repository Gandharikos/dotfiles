{lib, ...}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) enum;
in {
  imports = lib.my.scanPaths ./.;

  options.my.gui.desktop.lock = {
    default = mkOption {
      type = enum ["hyprlock" "dms"];
      default = "dms";
      description = "The lock screen to use.";
    };
  };
}
