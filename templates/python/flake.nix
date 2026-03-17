{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.poetry2nix.url = "github:nix-community/poetry2nix";

  outputs =
    {
      self,
      nixpkgs,
      poetry2nix,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgs = forAllSystems (system: nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (
        system:
        let
          inherit (poetry2nix.lib.mkPoetry2Nix { pkgs = pkgs.${system}; }) mkPoetryApplication overrides;
        in
        {
          default = mkPoetryApplication {
            projectDir = self;
            overrides = overrides.withDefaults (
              final: prev: {
                # Fix for mypy-extensions build issue
                mypy-extensions = prev.mypy-extensions.overridePythonAttrs (old: {
                  buildInputs = (old.buildInputs or [ ]) ++ [ final.flit-core ];
                });
              }
            );
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          inherit (poetry2nix.lib.mkPoetry2Nix { pkgs = pkgs.${system}; }) mkPoetryEnv overrides;
        in
        {
          default = pkgs.${system}.mkShellNoCC {
            packages = with pkgs.${system}; [
              (mkPoetryEnv {
                projectDir = self;
                overrides = overrides.withDefaults (
                  final: prev: {
                    # Fix for mypy-extensions build issue
                    mypy-extensions = prev.mypy-extensions.overridePythonAttrs (old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ final.flit-core ];
                    });
                  }
                );
              })
              poetry
            ];
          };
        }
      );
    };
}
