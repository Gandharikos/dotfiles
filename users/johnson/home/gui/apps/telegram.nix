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
    # macOS uses the Homebrew cask to avoid building Telegram and Qt locally.
    home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.telegram-desktop ];
  };
}
