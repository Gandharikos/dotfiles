{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.lists) optionals;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
in
{
  imports = lib.dot.scanPaths ./.;

  config = mkIf osConfig.dot.gui.enable {
    home.packages =
      with pkgs;
      optionals isLinux [
        calibre
        teams-for-linux
      ];
  };
}
