{config, ...}: let
  cfg = config.my.gui.desktop.login;
in {
  services.displayManager.cosmic-greeter.enable = cfg == "cosmic-greeter";
}
