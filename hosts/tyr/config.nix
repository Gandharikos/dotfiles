{
  dot = {
    primaryUser = "johnson";
    machine.type = "desktop";
    networking.tailscale.role = "router-exit-node";
    keyboard = {
      layout = "qwerty";
      backend = "kanata";
    };
    users.johnson.home.my.gui.terminal.size = 14;
  };
}
