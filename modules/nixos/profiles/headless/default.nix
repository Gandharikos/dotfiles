{
  lib,
  config,
  ...
}:
let
  inherit (lib.my) scanPaths;
  inherit (lib.modules) mkIf mkForce;
  inherit (config.my.machine) type;
  # NOTE: wsl can use graphical desktop by docker, but it's not recommended
  isHeadless = type == "wsl" || type == "server" || type == "mobile";
in
{
  imports = scanPaths ./.;

  config = mkIf isHeadless {
    my.gui.enable = mkForce false;
    hm.my.gui.enable = mkForce false;
  };
}
