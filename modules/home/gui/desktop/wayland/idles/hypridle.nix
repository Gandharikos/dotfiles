{
  lib,
  config,
  ...
}:
let
  inherit (lib.lists) optionals;
  inherit (lib.modules) mkIf;

  inherit (config.my.gui) desktop;
  cfg = desktop.idle;
  inherit (cfg) timeout;
  inherit (cfg.commands)
    lock
    lockSession
    screenOn
    screenOff
    dimScreen
    restoreScreen
    suspend
    keyboardBacklightOff
    keyboardBacklightOn
    ;

  enable = desktop.idle.default == "hypridle" && desktop.wayland.enable;
in
{
  config = mkIf enable {
    home.shellAliases.caffeinate = "systemctl --user stop hypridle";

    services.hypridle = {
      enable = true;

      settings = {
        general = {
          lock_cmd = lock;
          before_sleep_cmd = lockSession;
          after_sleep_cmd = screenOn;
        };

        listener = [
          {
            timeout = timeout - 10;
            on-timeout = toString dimScreen;
            on-resume = restoreScreen;
          }
        ]
        ++ optionals cfg.keyboardBacklight.enable [
          {
            timeout = timeout / 2;
            on-timeout = keyboardBacklightOff;
            on-resume = keyboardBacklightOn;
          }
        ]
        ++ [
          {
            inherit timeout;
            on-timeout = lockSession;
          }
          {
            inherit timeout;
            on-timeout = screenOff;
            on-resume = screenOn;
          }
          {
            timeout = timeout + 10;
            on-timeout = toString suspend;
          }
        ];
      };
    };
  };
}
