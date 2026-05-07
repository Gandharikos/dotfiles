{ lib, ... }:
{
  imports = lib.dot.scanPaths ./.;

  options.my.langs = {
    enable = lib.mkEnableOption "development environment" // {
      default = true;
    };
  };
}
