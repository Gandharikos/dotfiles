{
  lib,
  config,
  inputs',
  pkgs,
  ...
}:
let
  cfg = config.dot.langs.rust;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkMerge mkIf;
  inherit (lib.lists) optionals;
  inherit (config) xdg;
  fenixPkgs = inputs'.fenix.packages;
  rustToolchain = fenixPkgs.stable.withComponents [
    "cargo"
    "clippy"
    "rust-src"
    "rustc"
    "rustfmt"
  ];
in
{
  options.dot.langs.rust = {
    enable = mkEnableOption "Rust development environment";
    xdg.enable = mkEnableOption "Rust XDG environment variables";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = [
        rustToolchain
        fenixPkgs.stable.rust-analyzer
        pkgs.bacon
        pkgs.cargo-audit
        pkgs.cargo-deny
        pkgs.cargo-edit
        pkgs.cargo-expand
        pkgs.cargo-generate
        pkgs.cargo-llvm-cov
        pkgs.cargo-nextest
        pkgs.cargo-watch
        pkgs.evcxr
        pkgs.openssl
        pkgs.pkg-config
        pkgs.sccache
      ]
      ++ optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.mold
      ];
      home.shellAliases = {
        rs = "rustc";
        ca = "cargo";
      };
    })

    (mkIf cfg.xdg.enable {
      home.sessionPath = [ "${xdg.dataHome}/cargo/bin" ];

      home.sessionVariables = rec {
        CARGO_HOME = "${xdg.dataHome}/cargo";
        RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
      };
    })
  ];
}
