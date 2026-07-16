{
  lib,
  stdenv,
  cmake,
  ninja,
}:

stdenv.mkDerivation {
  pname = "cpp-app";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../CMakeLists.txt
      ../src
    ];
  };

  nativeBuildInputs = [
    cmake
    ninja
  ];

  meta = {
    description = "A minimal C++20 application";
    mainProgram = "cpp-app";
    platforms = lib.platforms.unix;
  };
}
