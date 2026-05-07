{
  lib,
  config,
  ...
}:
let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) enum;
  inherit (lib.dot) scanPaths;
in
{
  imports = scanPaths ./.;

  options.dot.gui.login = {
    default = mkOption {
      type = enum [
        "greetd"
        "sddm"
        "cosmic-greeter"
      ];
      default = "greetd";
      description = "Desktop login manager";
    };

    greetd.enable = mkEnableOption "greetd login manager" // {
      default = config.dot.gui.enable && config.dot.gui.login.default == "greetd";
      internal = true;
      readOnly = true;
    };

    sddm.enable = mkEnableOption "sddm login manager" // {
      default = config.dot.gui.enable && config.dot.gui.login.default == "sddm";
      internal = true;
      readOnly = true;
    };

    cosmicGreeter.enable = mkEnableOption "cosmic-greeter login manager" // {
      default = config.dot.gui.enable && config.dot.gui.login.default == "cosmic-greeter";
      internal = true;
      readOnly = true;
    };
  };
}
