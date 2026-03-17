{
  lib,
  config,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.my.machine) hasPrinter;
in
{
  options.my.machine.hasPrinter = mkEnableOption "Whether has printer support";

  config = mkIf hasPrinter {
    services.printing = {
      enable = true;
      startWhenNeeded = true;
      # logLevel = "debug";
    };
  };
}
