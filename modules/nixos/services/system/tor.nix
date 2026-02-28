{
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.my) desktop;
  cfg = config.my.services.tor;
in {
  options.my.services.tor = {
    enable =
      mkEnableOption "Enable Tor"
      // {
        default = desktop.enable;
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
