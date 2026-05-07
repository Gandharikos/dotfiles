{
  lib,
  config,
  ...
}:
let
  cfg = config.dot.services.printing;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in
{
  options.dot.services.printing = {
    enable = mkEnableOption "Enable printing";
  };

  config = mkIf cfg.enable {
    # Network discovery, mDNS, DNS-SD
    # With this enabled, you can access your machine at <hostname>.local
    # it's more convenient than using IP addresses
    # https://avahi.org/
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        domain = true;
        userServices = true;
      };
    };

    services.printing = {
      browsing = true;
      listenAddresses = [ "*:631" ];
      allowFrom = [ "all" ];
      defaultShared = true;
    };

    networking.firewall = {
      allowedUDPPorts = [ 631 ];
      allowedTCPPorts = [ 631 ];
    };
  };
}
