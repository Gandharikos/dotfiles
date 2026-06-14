{ lib, osConfig, ... }:
let
  isMinimal = osConfig ? dot && osConfig.dot.profiles.minimal.enable or false;
in
{
  imports = lib.dot.scanPaths ./.;

  options.my.langs = {
    enable = lib.mkEnableOption "development environment" // {
      default = !isMinimal;
    };
  };
}
