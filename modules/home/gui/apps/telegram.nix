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
  cfg = config.my.gui.apps.telegram;
  enable = osConfig.dot.gui.enable && cfg.enable;
in
{
  options.my.gui.apps.telegram = {
    enable = mkEnableOption "Telegram";
  };

  config = mkIf enable {
    home.packages = with pkgs; [
      # instant messaging
      telegram-desktop
    ];
  };
}
