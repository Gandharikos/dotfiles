{config, ...}: let
  cfg = config.my.desktop.login;
in {
  services.displayManager.cosmic-greeter.enable = cfg == "cosmic-greeter";
}
