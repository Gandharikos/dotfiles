{config, ...}: let
  inherit (config.my) gui;
  enable = gui.login.default == "cosmic-greeter" && gui.enable;
in {
  services.displayManager.cosmic-greeter.enable = enable;
}
