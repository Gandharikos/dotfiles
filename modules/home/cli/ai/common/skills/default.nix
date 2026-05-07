{ lib, pkgs, ... }:
let
  inherit (lib.dot) scanPaths;
  args = { inherit lib pkgs; };
in
lib.foldl' (acc: path: acc // import path args) { } (scanPaths ./.)
