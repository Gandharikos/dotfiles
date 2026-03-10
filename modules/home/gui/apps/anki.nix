{
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.gui.apps.anki;
in {
  options.my.gui.apps.anki = {
    enable =
      mkEnableOption "anki"
      // {
        default = config.my.gui.enable;
      };
  };

  config = mkIf cfg.enable {
    programs.anki = {
      # BUG: anki package is broken on nixpkgs-unstable as of 2024-06-10
      enable = false;
    };
  };
}
