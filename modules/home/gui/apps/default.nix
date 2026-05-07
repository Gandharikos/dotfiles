{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.lists) optionals;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (config.dot) gui;
in
{
  imports = lib.dot.scanPaths ./.;

  config = mkIf gui.enable {
    home.packages =
      with pkgs;
      optionals isLinux [
        calibre
        teams-for-linux
      ];
  };
}
