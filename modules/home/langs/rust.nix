{
  lib,
  config,
  inputs',
  ...
}:
let
  cfg = config.my.langs.rust;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkMerge mkIf;
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
    xdg.enable = mkEnableOption "Rust XDG environment variables";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = [
        rustToolchain
        fenixPkgs.stable.rust-analyzer
      ];
      home.shellAliases = {
        rs = "rustc";
        ca = "cargo";
      };
    })

    (mkIf cfg.xdg.enable {
      home.sessionVariables = rec {
        CARGO_HOME = "${xdg.dataHome}/cargo";
        PATH = [ "${CARGO_HOME}/bin" ];
        RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
      };
    })
  ];
}
