{ lib, ... }:
{
  _class = "darwin";
  imports = (lib.my.scanPaths ./.) ++ [ ../common ];
}
