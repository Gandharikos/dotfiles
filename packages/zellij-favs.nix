{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zellij-favs";
  version = "v1.0.2";
  src = fetchurl {
    url = "https://github.com/JoseMM2002/zellij-favs/releases/download/${version}/zellij-favs.wasm";
    sha256 = "sha256-yiP4i5kiS+41tHqwWvO0nvpvZbxtrZYnFUT1bKY9LSc=";
  };
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${pname}.wasm
    chmod +x $out/bin/${pname}.wasm
  '';

  meta = with lib; {
    description = "A simple and intuitive plugin for managing favorite sessions in Zellij. Easily organize and switch between sessions with ease.";
    homepage = "https://github.com/JoseMM2002/zellij-favs";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
