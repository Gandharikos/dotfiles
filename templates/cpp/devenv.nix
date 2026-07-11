{ pkgs, ... }:

{
  languages.cplusplus.enable = true;

  packages = [
    pkgs.cmake
    pkgs.cppcheck
    pkgs.glm
    pkgs.llvmPackages.lldb
    pkgs.ninja
    pkgs.SDL2
    pkgs.SDL2_gfx
  ];
}
