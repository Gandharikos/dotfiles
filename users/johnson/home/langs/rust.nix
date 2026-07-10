{
  lib,
  config,
  inputs',
  pkgs,
  ...
}:
let
  cfg = config.my.langs.rust;
  enable = config.my.langs.enable && cfg.enable;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
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
  options.my.langs.rust = {
    enable = mkEnableOption "Rust development environment";
  };

  config = mkIf enable {
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

    home.sessionPath = [ "${xdg.dataHome}/cargo/bin" ];

    home.sessionVariables = {
      CARGO_HOME = "${xdg.dataHome}/cargo";
      RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
    };
  };
}
