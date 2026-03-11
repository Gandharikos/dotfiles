{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (config.my) gui;
  cfg = config.my.gui.apps.telegram;
  enable = gui.enable && cfg.enable;
in {
  options.my.gui.apps.telegram = {
    enable =
      mkEnableOption "Telegram"
      // {
        default = true;
      };
  };

  config = mkIf enable {
    home.packages = with pkgs; [
      # instant messaging
      telegram-desktop
    ];
  };
}
