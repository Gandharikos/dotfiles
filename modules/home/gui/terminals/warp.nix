{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.my) gui;
  cfg = config.my.gui.apps.warp;
  enable = gui.enable && cfg.enable;
in {
  options.my.gui.apps.warp = {
    enable =
      mkEnableOption "warp"
      // {
        default = config.my.gui.terminal.default == "warp";
      };
  };

  config = mkIf enable {
    home.packages = with pkgs; [warp-terminal];
  };
}
