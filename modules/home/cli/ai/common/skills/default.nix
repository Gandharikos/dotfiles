{ lib, pkgs, ... }:
let
  inherit (lib.my) scanPaths;
  args = { inherit lib pkgs; };
in
lib.foldl' (acc: path: acc // import path args) { } (scanPaths ./.)
