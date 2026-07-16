{ lib, ... }:
let
  # Root-level templates directory
  templateDir = ../templates;

  # Read directory entries and keep only subdirectories
  entries = builtins.readDir templateDir;
  templateNames = builtins.attrNames (
    lib.attrsets.filterAttrs (_name: typ: typ == "directory") entries
  );
  templates = lib.genAttrs templateNames (name: {
    path = lib.path.append templateDir name;
    description = "Project template: ${name}";
  });
in
{
  # Expose all templates for `nix flake init -t .#<name>` or `nix flake new <dst> -t .#<name>`
  flake.templates = templates;

  # Omnix wraps standard flake templates so `om init .` can present one interactive menu.
  flake.om.templates = lib.mapAttrs (_name: template: {
    inherit template;
    params = [ ];
  }) templates;
}
