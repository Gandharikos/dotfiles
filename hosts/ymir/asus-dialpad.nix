{ inputs, ... }:
{
  imports = [
    inputs.asus-dialpad-driver.nixosModules.default
  ];

  services.asus-dialpad-driver = {
    enable = false;
    layout = "proartp16";
    wayland = true;
    ignoreWaylandDisplayEnv = true;
    runtimeDir = "/run/user/1000/";
    waylandDisplay = "wayland-0";
  };
}
