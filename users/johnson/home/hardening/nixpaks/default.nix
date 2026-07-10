{
  callPackage,
  lib,
  mkNixPak,
  pkgs,
}:
let
  callNixPak = path: callPackage path { inherit mkNixPak; };
in
{
  qq = callNixPak ./qq.nix;

  helpers = {
    inherit mkNixPak;
    inherit (lib) getExe;
    inherit pkgs;
  };
}
