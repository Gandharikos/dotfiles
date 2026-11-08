{ lib, ... }:
{
  networking = {
    nftables.enable = true;
    firewall = {
      enable = lib.mkDefault true;
      allowPing = lib.mkDefault true;
      checkReversePath = lib.mkDefault "loose";
      logReversePathDrops = lib.mkDefault false;
      logRefusedConnections = lib.mkDefault false;
    };
  };
}
