{
  description = "Python project template using devenv";

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
          pyproject = builtins.fromTOML (builtins.readFile ./pyproject.toml);
          pkgs = nixpkgs.legacyPackages.${system};
          python = pkgs.python3;
        in
        {
          default = python.pkgs.buildPythonApplication {
            pname = pyproject.project.name;
            inherit (pyproject.project) version;

            src = ./.;
            pyproject = true;

            build-system = [ python.pkgs.uv-build ];
          };
        }
      );

      apps = forAllSystems (
        system:
        let
          pyproject = builtins.fromTOML (builtins.readFile ./pyproject.toml);
        in
        {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/${pyproject.project.name}";
          };
        }
      );
    };
}
