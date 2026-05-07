{ lib, ... }:
{
  _class = "nixos";
  imports = (lib.dot.scanPaths ./.) ++ [ ../common ];
}
