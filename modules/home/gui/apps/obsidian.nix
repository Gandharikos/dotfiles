{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (config.my) gui;
  cfg = config.my.gui.apps.obsidian;
  enable = gui.enable && cfg.enable;
in
{
  options.my.gui.apps.obsidian = {
    enable = mkEnableOption "Obsidian" // {
      default = true;
    };
  };

  config = mkIf enable {
    home.packages = with pkgs; [
      # note taking
      obsidian
    ];
  };
}
