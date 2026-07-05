{
  lib,
  ...
}:
let
  inherit (lib.dot) scanPaths;
in
{
  imports = scanPaths ./.;
}
