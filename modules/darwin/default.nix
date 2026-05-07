{ lib, ... }:
{
  _class = "darwin";
  imports = (lib.dot.scanPaths ./.) ++ [ ../common ];
}
