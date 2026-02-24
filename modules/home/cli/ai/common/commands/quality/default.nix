{lib, ...}:
lib.foldl' lib.recursiveUpdate {} [
  (import ./deep-check.nix)
  (import ./dependency-audit.nix)
  (import ./module-lint.nix)
  (import ./quick-check.nix)
  (import ./style-audit.nix)
]
