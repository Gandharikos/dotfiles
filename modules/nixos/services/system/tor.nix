{
  lib,
  config,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.dot) gui;
  cfg = config.dot.services.tor;
in
{
  options.dot.services.tor = {
    enable = mkEnableOption "Enable Tor" // {
      default = gui.enable;
    };
  };

  config = mkIf cfg.enable {
    services.tor = {
      enable = true;
      client.enable = true;
      client.dns.enable = true;
      torsocks.enable = true;
    };
  };
}
