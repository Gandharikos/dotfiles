{
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.my) isWayland;
  enable = isWayland config;
in {
  config = mkIf enable {
    programs.xwayland.enable = true;
  };
}
