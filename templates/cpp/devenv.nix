{ pkgs, ... }:

{
  languages.cplusplus.enable = true;

  packages = [
    pkgs.bear
    pkgs.cmake
    pkgs.cppcheck
    pkgs.glm
    pkgs.gnumake
    pkgs.llvmPackages.lldb
    pkgs.SDL2
    pkgs.SDL2_gfx
  ];
}
