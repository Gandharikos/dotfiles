{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkDefault mkForce;
  isWSL = config.dot.machine.type == "wsl";
  isProxy = config.dot.networking.proxy.enable;
  inherit (lib.options) mkEnableOption;
  cfg = config.dot.networking;
in
{
  imports = lib.dot.scanPaths ./.;
  options.dot.networking = {
    enableIPv6 = mkEnableOption "Enable IPv6 supprot" // {
      default = true;
    };
  };
  config = {
    networking = {
      # generate a host ID by hashing the hostname
      hostId = builtins.substring 0 8 (builtins.hashString "md5" config.networking.hostName);

      # this is setup to use the hostname the system builder provides, this is left here
      # as a note for readers to know this is how it works, and why hostName is never set
      # hostName = "nixos";

      # global dhcp has been deprecated upstream, so we use networkd instead
      # however individual interfaces are still managed through dhcp in hardware configurations
      useDHCP = mkForce isWSL;
      useNetworkd = mkForce (!isWSL);

      # interfaces are assigned names that contain topology information (e.g. wlp3s0) and thus should be consistent across reboots
      # this already defaults to true, we set it in case it changes upstream
      usePredictableInterfaceNames = mkDefault true;

      # dns
      nameservers = mkIf (!isWSL && !isProxy) [
        "1.1.1.1"
        "1.0.0.1"
        "9.9.9.9"
      ];

      inherit (cfg) enableIPv6;
    };
  };
}
