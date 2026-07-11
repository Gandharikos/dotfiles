{
  description = "Rust project template using devenv";

  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    devenv.url = "github:cachix/devenv";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-substituters = "https://devenv.cachix.org";
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      devenv,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [ ./devenv.nix ];
          };
        }
      );

      packages = forAllSystems (
        system:
        let
          cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.rustPlatform.buildRustPackage {
            pname = cargoToml.package.name;
            inherit (cargoToml.package) version;

            src = ./.;
            cargoLock.lockFile = ./Cargo.lock;
          };
        }
      );

      apps = forAllSystems (
        system:
        let
          cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
        in
        {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/${cargoToml.package.name}";
          };
        }
      );
    };
}
