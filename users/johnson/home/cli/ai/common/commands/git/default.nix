{ lib, ... }:
lib.foldl' lib.recursiveUpdate { } [
  (import ./add-and-format.nix)
  (import ./commit-changes.nix)
  (import ./commit-msg.nix)
  (import ./review.nix)
]
