{ lib, pkgs, ... }:
{
  imports = lib.dot.scanPaths ./.;
  home.packages = with pkgs; [
    pixi
  ];
}
