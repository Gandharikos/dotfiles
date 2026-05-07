{ lib, ... }:
{
  imports = lib.dot.scanPaths ./.;

  options.dot.langs = {
    enable = lib.mkEnableOption "development environment" // {
      default = true;
    };
  };
}
