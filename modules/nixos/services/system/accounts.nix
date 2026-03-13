{config, ...}: {
  # INFO: I don't want use this, but dms require it.
  services.accounts-daemon.enable = config.my.gui.enable;
}
