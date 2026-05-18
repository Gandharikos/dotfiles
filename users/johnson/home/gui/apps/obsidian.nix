{
  config,
  osConfig,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.gui.apps.obsidian;
  enable = osConfig.dot.gui.enable && cfg.enable;
in
{
  options.my.gui.apps.obsidian = {
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
