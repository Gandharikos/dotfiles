{ config, ... }:
{
  services.displayManager.cosmic-greeter.enable = config.dot.gui.login.cosmicGreeter.enable;
}
