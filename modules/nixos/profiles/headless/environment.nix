{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.dot.profiles.headless;
in
{
  config = mkIf cfg.enable {
    # print the URL instead on servers
    environment.variables.BROWSER = "echo";
  };
}
