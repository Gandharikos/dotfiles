{
  description = "Node.js project template using devenv";

  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    devenv.url = "github:cachix/devenv";
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
          packageJson = builtins.fromJSON (builtins.readFile ./package.json);
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.buildNpmPackage {
            pname = packageJson.name;
            inherit (packageJson) version;

            src = ./.;
            npmDepsHash = "sha256-n8Skk1Gt2MgGhrYeSya0IFsXVZ1gAwQRZb80xbcZkrQ=";
            npmBuildScript = "build";
          };
        }
      );

      apps = forAllSystems (
        system:
        let
          packageJson = builtins.fromJSON (builtins.readFile ./package.json);
          packageBin = builtins.elemAt (builtins.attrNames packageJson.bin) 0;
        in
        {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/${packageBin}";
          };
        }
      );
    };
}
