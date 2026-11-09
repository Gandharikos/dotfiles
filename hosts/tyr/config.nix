{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.dot.krd ];

  dot = {
    primaryUser = "johnson";
    device.type = "desktop";
    networking.tailscale = {
      role = "router-exit-node";
      advertiseRoutes = [ "192.168.1.0/24" ];
    };
    keyboard = {
      layout = "qwerty";
      backend = "kanata";
    };
  };
}
