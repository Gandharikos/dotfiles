{lib, ...}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) enum;
  inherit (lib.my) scanPaths;
in {
  imports = scanPaths ./.;

  options.my.gui.login.default = mkOption {
    type = enum [
      "greetd"
      "sddm"
      "cosmic-greeter"
    ];
    default = "greetd";
    description = "Desktop login manager";
  };
}
