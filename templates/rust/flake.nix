{
  description = "A batteries-included Rust project template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane.url = "github:ipetkov/crane";

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      crane,
      git-hooks,
      rust-overlay,
      ...
    }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      projectFor =
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ (import rust-overlay) ];
          };
          toolchainFor = p: p.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
          rustToolchain = toolchainFor pkgs;
          craneLib = (crane.mkLib pkgs).overrideToolchain toolchainFor;
          src = craneLib.cleanCargoSource ./.;
          commonArgs = {
            inherit src;
            strictDeps = true;
          };
          cargoArtifacts = craneLib.buildDepsOnly commonArgs;
          package = craneLib.buildPackage (
            commonArgs
            // {
              inherit cargoArtifacts;
            }
          );
          preCommitCheck = git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              check-added-large-files.enable = true;
              check-case-conflicts.enable = true;
              check-merge-conflicts.enable = true;
              clippy = {
                enable = true;
                package = rustToolchain;
                stages = [ "pre-push" ];
              };
              deadnix.enable = true;
              end-of-file-fixer.enable = true;
              mixed-line-endings.enable = true;
              nixfmt.enable = true;
              rustfmt = {
                enable = true;
                package = rustToolchain;
              };
              statix.enable = true;
              trim-trailing-whitespace.enable = true;
              typos.enable = true;
            };
          };
        in
        {
          inherit
            cargoArtifacts
            craneLib
            package
            pkgs
            preCommitCheck
            rustToolchain
            src
            ;

          clippy = craneLib.cargoClippy (
            commonArgs
            // {
              inherit cargoArtifacts;
              cargoClippyExtraArgs = "--all-targets -- --deny warnings";
            }
          );
          format = craneLib.cargoFmt { inherit src; };
          tests = craneLib.cargoTest (
            commonArgs
            // {
              inherit cargoArtifacts;
            }
          );
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          project = projectFor system;
        in
        {
          sample-rust = project.package;
          default = project.package;
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
            meta.description = "Run the Rust application";
          };
        }
      );

      checks = forAllSystems (
        system:
        let
          project = projectFor system;
        in
        {
          inherit (project)
            clippy
            format
            package
            tests
            ;
          pre-commit-check = project.preCommitCheck;
        }
      );

      devShells = forAllSystems (
        system:
        let
          project = projectFor system;
        in
        {
          default = project.pkgs.mkShell {
            inputsFrom = [ project.package ];
            packages = project.preCommitCheck.enabledPackages ++ [
              project.rustToolchain
              project.pkgs.bacon
              project.pkgs.just
            ];

            shellHook = ''
              ${project.preCommitCheck.shellHook}
              echo "Rust $(rustc --version | cut -d' ' -f2) development environment"
              echo "Run 'just check' to format, lint, and test the project."
            '';
          };
        }
      );

      formatter = forAllSystems (
        system:
        let
          project = projectFor system;
          inherit (project.preCommitCheck.config) package configFile;
        in
        project.pkgs.writeShellScriptBin "sample-rust-format" ''
          exec ${project.pkgs.lib.getExe package} run --all-files --config ${configFile}
        ''
      );
    };
}
