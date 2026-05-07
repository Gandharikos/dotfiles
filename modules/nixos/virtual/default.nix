{ lib, ... }:
{
  imports = lib.dot.scanPaths ./.;

  options.dot.virtual = {
    enable = lib.mkEnableOption "Virtualisation";
  };
}
