{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.gui.terminals.warp;
in {
  options.my.gui.terminals.warp = {
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
