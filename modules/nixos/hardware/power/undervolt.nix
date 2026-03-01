{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (config.my) machine;
in {
  config = mkIf (machine.type == "laptop") {
    # temperature target on battery
    services.undervolt = {
      enable = machine.cpu == "intel";
      tempBat = 65; # deg C
      package = pkgs.undervolt;
    };
  };
}
