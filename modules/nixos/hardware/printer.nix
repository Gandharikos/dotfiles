{
  lib,
  config,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.dot.device) hasPrinter;
in
{
  options.dot.device.hasPrinter = mkEnableOption "Whether has printer support";

  config = mkIf hasPrinter {
    services.printing = {
      enable = true;
      startWhenNeeded = true;
      # logLevel = "debug";
    };
  };
}
