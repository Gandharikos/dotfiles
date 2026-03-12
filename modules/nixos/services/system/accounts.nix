{config, ...}: {
  services.accounts-daemon.enable = config.my.gui.enable;
}
