{
  lib,
  config,
  ...
}:
let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) enum;
  inherit (lib.my) scanPaths;
in
{
  imports = scanPaths ./.;

  options.my.gui.login = {
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
      default = config.my.gui.enable && config.my.gui.login.default == "greetd";
      internal = true;
      readOnly = true;
    };

    sddm.enable = mkEnableOption "sddm login manager" // {
      default = config.my.gui.enable && config.my.gui.login.default == "sddm";
      internal = true;
      readOnly = true;
    };

    cosmicGreeter.enable = mkEnableOption "cosmic-greeter login manager" // {
      default = config.my.gui.enable && config.my.gui.login.default == "cosmic-greeter";
      internal = true;
      readOnly = true;
    };
  };
}
