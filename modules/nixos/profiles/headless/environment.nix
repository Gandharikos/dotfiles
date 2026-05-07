{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  isHeadless = !config.dot.gui.enable;
in
{
  config = mkIf isHeadless {
    # print the URL instead on servers
    environment.variables.BROWSER = "echo";
  };
}
