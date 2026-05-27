{
  dot = {
    primaryUser = "johnson";
    machine.type = "desktop";
    networking.tailscale = {
      role = "router-exit-node";
      advertiseRoutes = [ "192.168.1.0/24" ];
    };
    keyboard = {
      layout = "qwerty";
      backend = "kanata";
    };
    users.johnson.home.my.gui.terminal.size = 14;
  };
}
