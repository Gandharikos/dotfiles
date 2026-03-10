{
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) nullOr enum;
  inherit (lib.my) scanPaths;
  cfg = config.my.gui.desktop;
in {
  imports = scanPaths ./.;

  options.my.gui.desktop.login = mkOption {
    type = nullOr (enum [
      "greetd"
      "sddm"
      "cosmic-greeter"
    ]);
    default =
      if cfg.enable
      then "greetd"
      else null;
    description = "Desktop login manager";
  };
}
