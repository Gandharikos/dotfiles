{ lib, ... }:
{
  _class = "homeManager";
  imports = (lib.dot.scanPaths ./.) ++ [
    ../common/ai
  ];
}
