{
  dot = {
    primaryUser = "johnson";
    device.type = "server";
    profiles.minimal.enable = true;
    gui.enable = false;
    networking.tailscale = {
      role = "router-exit-node";
      advertiseRoutes = [ "192.168.1.0/24" ];
    };
    keyboard = {
      layout = "qwerty";
      backend = null;
    };
  };
}
