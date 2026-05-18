{ lib, ... }:
let
  inherit (lib.modules) mkDefault;
  secretsCore = lib.dot.getFile "secrets/johnson/core";
in
{
  imports = lib.dot.scanPaths ./.;

  my.security.gpg = {
    key = mkDefault "776C7FC245E58F55";
    publicKeysPath = mkDefault (secretsCore + "/gpg-keys.pub");
    encrytionKey = mkDefault "6E714D9B24EF3018DB51E7892BE66A4F9E095541";
    signatureKey = mkDefault "EC571D2B91912D528A9F3B00639746C15BE596AF";
  };
}
