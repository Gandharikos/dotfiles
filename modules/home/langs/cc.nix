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
        gcc
        llvmPackages.clang-tools
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
