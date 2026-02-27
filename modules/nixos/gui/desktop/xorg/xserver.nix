{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.my) isXorg;
  enable = isXorg config;
in {
  config = mkIf enable {
    services.xserver.excludePackages = [
      pkgs.xterm
    ];
  };
}
