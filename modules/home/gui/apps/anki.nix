{
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.desktop.apps.anki;
in {
  options.my.desktop.apps.anki = {
    enable =
      mkEnableOption "anki"
      // {
        default = config.my.desktop.enable;
      };
  };

  config = mkIf cfg.enable {
    programs.anki = {
      # BUG: anki package is broken on nixpkgs-unstable as of 2024-06-10
      enable = false;
    };
  };
}
