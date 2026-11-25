{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.dot.krd ];

  dot = {
    primaryUser = "johnson";
    device.type = "desktop";
    networking.tailscale = {
      role = "subnet-router";
      # Heimdall owns general DNS during the scoped IPv4 gateway trial.
      acceptDns = false;
      advertiseRoutes = [ "192.168.1.0/24" ];
    };
    keyboard = {
      layout = "qwerty";
      backend = "kanata";
    };
  };
}
