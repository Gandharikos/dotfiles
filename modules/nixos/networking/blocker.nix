{
  lib,
  config,
  ...
}:
let
  isServer = config.dot.machine.type == "server";
  inherit (lib.modules) mkIf;
in
{
  config = mkIf (!isServer) {
    networking.stevenblack = {
      enable = true;
      block = [
        "fakenews"
        "gambling"
        "porn"
        # "social"
      ];
    };
  };
}
