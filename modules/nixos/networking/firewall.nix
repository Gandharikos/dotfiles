{ lib, ... }:
{
  networking.firewall.enable = lib.mkDefault true;
}
