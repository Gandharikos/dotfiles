{ lib, ... }:
lib.foldl' lib.recursiveUpdate { } [
  (import ./flake-expert.nix)
  (import ./module-expert.nix)
  (import ./nix-expert.nix)
]
