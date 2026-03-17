{ lib, ... }:
{
  _class = "nixos";
  imports = (lib.my.scanPaths ./.) ++ [ ../common ];
}
