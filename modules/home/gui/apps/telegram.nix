{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (config.dot) gui;
  cfg = config.dot.gui.apps.telegram;
  enable = gui.enable && cfg.enable;
in
{
  options.dot.gui.apps.telegram = {
    enable = mkEnableOption "Telegram";
  };

  config = mkIf enable {
    home.packages = with pkgs; [
      # instant messaging
      telegram-desktop
    ];
  };
}
