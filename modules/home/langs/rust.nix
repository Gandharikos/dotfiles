# modules/dev/rust.nix --- https://rust-lang.org
#
# Oh Rust. The light of my life, fire of my loins. Years of C++ has conditioned
# me to believe there was no hope left, but the gods have heard us. Sure, you're
# not going to replace C/C++. Sure, your starlight popularity has been
# overblown. Sure, macros aren't namespaced, cargo bypasses crates.io, and there
# is no formal proof of your claims for safety, but who said you have to solve
# all the world's problems to be wonderful?
{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.my.langs.rust;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkMerge mkIf;
  inherit (config) xdg;
in {
  options.my.langs.rust = {
    enable = mkEnableOption "Rust development environment";
    xdg.enable = mkEnableOption "Rust XDG environment variables";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = [pkgs.rustup];
      home.shellAliases = {
        rs = "rustc";
        rsp = "rustup";
        ca = "cargo";
      };
    })

    (mkIf cfg.xdg.enable {
      home.sessionVariables = rec {
        RUSTUP_HOME = "${xdg.dataHome}/rustup";
        CARGO_HOME = "${xdg.dataHome}/cargo";
        PATH = ["${CARGO_HOME}/bin"];
      };
    })
  ];
}
