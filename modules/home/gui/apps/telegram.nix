{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.gui.apps.telegram;
in {
  options.my.gui.apps.telegram = {
    enable =
      mkEnableOption "Telegram";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # instant messaging
      telegram-desktop
    ];
  };
}
