{ lib, ... }:
{
  imports = lib.dot.scanPaths ./.;
}
