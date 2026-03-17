{ lib, ... }:
{
  imports = lib.my.scanPaths ./.;

  options.my.virtual = {
    enable = lib.mkEnableOption "Virtualisation";
  };
}
