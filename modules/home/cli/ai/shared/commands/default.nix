{ lib, ... }:
lib.foldl' lib.recursiveUpdate { } [
  (import ./git { inherit lib; })
  (import ./nix { inherit lib; })
  (import ./quality { inherit lib; })
  (import ./project { inherit lib; })
]
