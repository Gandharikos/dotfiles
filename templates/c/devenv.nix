{ pkgs, ... }:

{
  languages.c.enable = true;

  packages = [
    pkgs.autoconf
    pkgs.automake
    pkgs.gnumake
    pkgs.libtool
    pkgs.pkg-config
  ];
}
