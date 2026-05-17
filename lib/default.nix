{ lib, ... }:
let
  arg = { inherit lib; };
  core = import ./core.nix arg;
in
core.deepMerge [
  core
  (core.importAndMerge [
    ./paths.nix
    ./modules.nix
    ./hardware.nix
    ./geometry.nix
    ./workspaces.nix
    ./commands.nix
    ./users.nix
  ] arg)
]
