{
  lib,
  config,
  ...
}:
let
  inherit (lib.dot) scanPaths;
  inherit (lib.modules) mkIf mkForce;
  inherit (config.dot.machine) type;
  # NOTE: wsl can use graphical desktop by docker, but it's not recommended
  isHeadless = type == "wsl" || type == "server" || type == "mobile";
in
{
  imports = scanPaths ./.;

  config = mkIf isHeadless {
    dot.gui.enable = mkForce false;
    hm.dot.gui.enable = mkForce false;
  };
}
