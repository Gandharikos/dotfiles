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

  cpp17 = pkgs.writeShellApplication {
    name = "cpp17";
    runtimeInputs = [ pkgs.gcc ];
    text = ''
      exec c++ -std=c++17 -Wall -Wextra -O2 "$@"
    '';
  };

  cpp20 = pkgs.writeShellApplication {
    name = "cpp20";
    runtimeInputs = [ pkgs.gcc ];
    text = ''
      exec c++ -std=c++20 -Wall -Wextra -O2 "$@"
    '';
  };

  cppdbg = pkgs.writeShellApplication {
    name = "cppdbg";
    runtimeInputs = [ pkgs.gcc ];
    text = ''
      exec c++ -std=c++17 -Wall -Wextra -Wshadow -g -O0 -fsanitize=address,undefined -fno-omit-frame-pointer "$@"
    '';
  };

  cpprun = pkgs.writeShellApplication {
    name = "cpprun";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gcc
    ];
    text = ''
      if [ "$#" -lt 1 ]; then
        echo "usage: cpprun <source.cc> [args...]" >&2
        exit 2
      fi

      source_file="$1"
      shift
      output_file="''${TMPDIR:-/tmp}/$(basename "''${source_file%.*}")"

      c++ -std=c++17 -Wall -Wextra -O2 "$source_file" -o "$output_file"
      exec "$output_file" "$@"
    '';
  };

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
      home.packages =
        with pkgs;
        [
          gcc
          llvmPackages.clang-tools
          bear
          cmake
          llvmPackages.libcxx

          # Respect XDG, damn it!
          (mkWrapper gdb ''
            wrapProgram "$out/bin/gdb" --add-flags '-q -x "$XDG_CONFIG_HOME/gdb/init"'
          '')
        ]
        ++ [
          cpp17
          cpp20
          cppdbg
          cpprun
        ];
    })

    (mkIf cfg.xdg.enable {
      # TODO
    })
  ];
}
