{
  lib,
  config,
  ...
}:
let
  cfg = config.my.services.proxy;
  inherit (lib.modules) mkIf;
in
{
  config = mkIf cfg.enable {
    services.sing-box = {
      # Disabled as per user request.
      enable = false;
    };
  };
}
