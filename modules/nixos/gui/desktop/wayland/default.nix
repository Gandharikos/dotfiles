{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf mkDefault;
  inherit (lib.my) scanPaths isWayland;
  enable = isWayland config;
in {
  imports = scanPaths ./.;

  config = mkIf enable {
    services.xserver.enable = mkDefault false;
  };
}
