{
  pkgs,
  config,
  osConfig,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.my.gui.apps.slack;
  enable = osConfig.dot.gui.enable && isLinux && cfg.enable;
in
{
  options.my.gui.apps.slack = {
    enable = mkEnableOption "Slack";
  };

  config = mkIf enable {
    home.packages = with pkgs; [
      slack
    ];
  };
}
