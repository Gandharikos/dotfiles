{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.desktop.apps.warp;
in {
  options.my.desktop.apps.warp = {
    enable =
      mkEnableOption "warp"
      // {
        default = config.my.terminal.default == "warp";
      };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [warp-terminal];
  };
}
