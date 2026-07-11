{ pkgs, ... }:

{
  languages.rust = {
    enable = true;
    channel = "stable";
    components = [
      "rustc"
      "cargo"
      "clippy"
      "rustfmt"
      "rust-analyzer"
    ];
  };

  packages = [ pkgs.pre-commit ];

  git-hooks.hooks = {
    rustfmt.enable = true;
    clippy.enable = true;
  };
}
