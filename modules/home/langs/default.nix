{ lib, ... }:
{
  imports = lib.my.scanPaths ./.;

  options.my.langs = {
    enable = lib.mkEnableOption "development environment" // {
      default = true;
    };
  };
}
