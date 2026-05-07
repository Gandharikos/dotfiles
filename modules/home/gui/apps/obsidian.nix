{
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (config.dot) gui;
  cfg = config.dot.gui.apps.obsidian;
  enable = gui.enable && cfg.enable;
in
{
  options.dot.gui.apps.obsidian = {
    enable = mkEnableOption "Obsidian" // {
      default = true;
    };
  };

  config = mkIf enable {
    programs.obsidian = {
      enable = true;
      cli.enable = true;
    };
  };
}
