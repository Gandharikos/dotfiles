{
  lib,
  config,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.dot.machine) hasPrinter;
in
{
  options.dot.machine.hasPrinter = mkEnableOption "Whether has printer support";

  config = mkIf hasPrinter {
    services.printing = {
      enable = true;
      startWhenNeeded = true;
      # logLevel = "debug";
    };
  };
}
