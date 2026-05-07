{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.dot) isx86Linux;
in
{
  hardware.graphics = {
    enable = true;
    enable32Bit = isx86Linux pkgs;
  };
}
