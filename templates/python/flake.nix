{
  description = "A batteries-included Python project template using uv2nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pyproject-nix.follows = "pyproject-nix";
        uv2nix.follows = "uv2nix";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      git-hooks,
      pyproject-nix,
      uv2nix,
      pyproject-build-systems,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = lib.genAttrs supportedSystems;

      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };
      overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };
      editableOverlay = workspace.mkEditablePyprojectOverlay { root = "$REPO_ROOT"; };

      pythonSets = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        (pkgs.callPackage pyproject-nix.build.packages { python = pkgs.python3; }).overrideScope (
          lib.composeManyExtensions [
            pyproject-build-systems.overlays.wheel
            overlay
          ]
        )
      );

      projectFor =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pythonSet = pythonSets.${system};
          editablePythonSet = pythonSet.overrideScope editableOverlay;
          applicationEnv = pythonSet.mkVirtualEnv "sample-python-env" workspace.deps.default;
          developmentEnv = editablePythonSet.mkVirtualEnv "sample-python-dev-env" workspace.deps.all;
          testEnv = pythonSet.mkVirtualEnv "sample-python-test-env" workspace.deps.all;
          inherit (pkgs.callPackages pyproject-nix.build.util { }) mkApplication;
          application = mkApplication {
            venv = applicationEnv;
            package = pythonSet.sample-python;
          };
          tests = pkgs.stdenv.mkDerivation {
            pname = "sample-python-tests";
            version = "0.1.0";
            src = ./.;
            nativeBuildInputs = [ testEnv ];
            dontConfigure = true;

            buildPhase = ''
              runHook preBuild
              pytest
              ruff format --check .
              ruff check .
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              touch $out
              runHook postInstall
            '';
          };
          preCommitCheck = git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              check-added-large-files.enable = true;
              check-case-conflicts.enable = true;
              check-merge-conflicts.enable = true;
              deadnix.enable = true;
              end-of-file-fixer.enable = true;
              mixed-line-endings.enable = true;
              nixfmt.enable = true;
              ruff.enable = true;
              ruff-format.enable = true;
              statix.enable = true;
              trim-trailing-whitespace.enable = true;
              typos.enable = true;
            };
          };
        in
        {
          inherit
            application
            developmentEnv
            editablePythonSet
            pkgs
            preCommitCheck
            tests
            ;
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          project = projectFor system;
        in
        {
          sample-python = project.application;
          default = project.application;
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/sample-python";
          meta.description = "Run the Python application";
        };
      });

      checks = forAllSystems (
        system:
        let
          project = projectFor system;
        in
        {
          package = project.application;
          inherit (project) tests;
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
            packages = project.preCommitCheck.enabledPackages ++ [
              project.developmentEnv
              project.pkgs.just
              project.pkgs.uv
            ];
            env = {
              UV_NO_SYNC = "1";
              UV_PYTHON = project.editablePythonSet.python.interpreter;
              UV_PYTHON_DOWNLOADS = "never";
            };
            shellHook = ''
              ${project.preCommitCheck.shellHook}
              unset PYTHONPATH
              export REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
              echo "Python $(python --version | cut -d' ' -f2) uv2nix development environment"
              echo "Run 'just check' to lint and test the project."
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
        project.pkgs.writeShellScriptBin "sample-python-format" ''
          exec ${project.pkgs.lib.getExe package} run --all-files --config ${configFile}
        ''
      );
    };
}
