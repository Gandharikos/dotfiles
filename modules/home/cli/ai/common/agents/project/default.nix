{ lib, ... }:
lib.foldl' lib.recursiveUpdate { } [
  (import ./dotfiles-expert.nix)
  (import ./system-config-expert.nix)
  (import ./template-designer.nix)
]
