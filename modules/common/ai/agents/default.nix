{ lib, ... }:
lib.foldl' lib.recursiveUpdate { } [
  (import ./nix { inherit lib; })
  (import ./project { inherit lib; })
  (import ./general { inherit lib; })
]
