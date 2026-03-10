{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.gui.apps.obsidian;
in {
  options.my.gui.apps.obsidian = {
    enable =
      mkEnableOption "Obsidian"
      // {
        default = config.my.gui.enable;
      };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # note taking
      obsidian
    ];
  };
}
