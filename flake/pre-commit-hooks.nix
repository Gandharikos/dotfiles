{inputs, ...}: {
  imports = [inputs.pre-commit-hooks.flakeModule];

  perSystem = {
    pre-commit = {
      # Add itself to `nix flake check`
      check.enable = false; # don't use this now
      settings = {
        excludes = ["flake.lock" ".direnv"];
        hooks = {
          # Filesystem
          check-added-large-files = {
            enable = true;
            excludes = ["\\.png" "\\.jpg"];
          };
          check-case-conflicts.enable = true;
          trim-trailing-whitespace.enable = true;
          end-of-file-fixer.enable = true;

          # Bash
          # many of the scripts in the config aren't executable because they don't need to be.
          check-shebang-scripts-are-executable.enable = false;
          check-executables-have-shebangs.enable = true;

          # Languages
          check-json.enable = true;
          check-toml.enable = true;

          # Nix
          nil.enable = true;
          treefmt.enable = true;
          deadnix.enable = true;

          # Misc
          actionlint.enable = true; # GitHub actions
          detect-private-keys.enable = true;
          check-merge-conflicts.enable = true;
          fix-byte-order-marker.enable = true;
          mixed-line-endings.enable = true;
          forbid-new-submodules.enable = true;
          # Conventional Commits
          commitizen.enable = true;
        };
        default_stages = [
          "pre-commit"
          "pre-push"
        ];
      };
    };
  };
}
