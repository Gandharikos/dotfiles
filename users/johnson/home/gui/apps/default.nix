{
  lib,
  pkgs,
  osConfig,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (lib.lists) optionals;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.my.gui.apps.bitwarden;
in
{
  imports = lib.dot.scanPaths ./.;

  options.my.gui.apps.bitwarden = {
    enable = mkEnableOption "Bitwarden" // {
      default = false;
    };
  };

  config = mkIf osConfig.dot.gui.enable {
    home.packages =
      with pkgs;
      optionals (isLinux && cfg.enable) [
        bitwarden-desktop
      ]
      ++ optionals isLinux [
        calibre
        teams-for-linux
      ];
  };
}
