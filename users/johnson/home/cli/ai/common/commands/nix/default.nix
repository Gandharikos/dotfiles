{ lib, ... }:
lib.foldl' lib.recursiveUpdate { } [
  (import ./flake-update.nix)
  (import ./module-scaffold.nix)
  (import ./nix-check.nix)
  (import ./option-migrate.nix)
  (import ./refactor.nix)
  (import ./template-new.nix)
]
