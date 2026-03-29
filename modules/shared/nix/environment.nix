{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (builtins) elem;
  inherit (lib.trivial) pipe;
  inherit (lib.lists) optionals;
  inherit (lib.attrsets) filterAttrs mapAttrs';
  inherit (lib.modules) mkForce;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  # for security reasons, do not load neovim's user config
  # since EDITOR may be used to edit some critical files
  environment = {
    variables = {
      EDITOR = "nvim --clean";
      NIXPKGS_CONFIG = mkForce "";
    };

    # etc."nixos/configuration.nix".source = pkgs.writeText "configuration.nix" ''
    #   assert builtins.trace "This is a dummy config, please deploy via the flake!" false;
    #   { }
    # '';
    # something something backwards compatibility something something nix channels
    etc =
      let
        inherit (config.nix) registry;
        commonPaths = [
          "nixpkgs"
          "home-manager"
        ]
        ++ optionals isDarwin [
          "nix-darwin"
        ];
      in
      pipe registry [
        (filterAttrs (name: _: (elem name commonPaths)))
        (mapAttrs' (
          name: value: {
            name = "nix/path/${name}";
            value.source = value.flake;
          }
        ))
      ];
  };
}
