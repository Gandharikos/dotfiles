{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.gui.apps.warp;
in {
  options.my.gui.apps.warp = {
    enable =
      mkEnableOption "warp"
      // {
        default = config.my.gui.terminal.default == "warp";
      };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [warp-terminal];
  };
}
