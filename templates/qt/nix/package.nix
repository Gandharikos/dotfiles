{
  lib,
  stdenv,
  cmake,
  ninja,
  qt6,
}:

stdenv.mkDerivation {
  pname = "qt-app";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../CMakeLists.txt
      ../include
      ../src
    ];
  };

  nativeBuildInputs = [
    cmake
    ninja
    qt6.wrapQtAppsHook
  ];

  buildInputs = [ qt6.qtbase ];

  meta = {
    description = "A minimal C++20 and Qt 6 Widgets application";
    mainProgram = "qt-app";
    platforms = lib.platforms.unix;
  };
}
