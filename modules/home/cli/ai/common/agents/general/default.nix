{lib, ...}:
lib.foldl' lib.recursiveUpdate {} [
  (import ./code-reviewer.nix)
  (import ./documenter.nix)
  (import ./security-auditor.nix)
]
