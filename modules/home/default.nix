{ lib, ... }:
{
  _class = "homeManager";
  imports = lib.my.scanPaths ./.;
}
