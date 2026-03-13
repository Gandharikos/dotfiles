{config, ...}: {
  services.displayManager.cosmic-greeter.enable = config.my.gui.login.cosmicGreeter.enable;
}
