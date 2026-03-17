# modules/dev/cc.nix --- C & C++
#
# I like C. I tolerate C++. I like++ C with a few choice C++ features tacked on.
# Liking C/C++ seems to be an unpopular opinion, so it's my guilty secret.
# Don't tell anyone pls.
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.my.langs.cc;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkMerge mkIf;
  inherit (builtins) isList elemAt;

  mkWrapper =
    package: postBuild:
    let
      name = if isList package then elemAt package 0 else package;
      paths = if isList package then package else [ package ];
    in
    pkgs.symlinkJoin {
      inherit paths postBuild;
      name = "${name}-wrapped";
      buildInputs = [ pkgs.makeWrapper ];
    };
in
{
  options.my.langs.cc = {
    enable = mkEnableOption "C/C++ development environment";
    xdg.enable = mkEnableOption "C/C++ XDG environment variables";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = with pkgs; [
        clang
        gcc
        bear
        cmake
        llvmPackages.libcxx

        # Respect XDG, damn it!
        (mkWrapper gdb ''
          wrapProgram "$out/bin/gdb" --add-flags '-q -x "$XDG_CONFIG_HOME/gdb/init"'
        '')
      ];
    })

    (mkIf cfg.xdg.enable {
      # TODO
    })
  ];
}
