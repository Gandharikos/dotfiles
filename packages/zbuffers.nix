{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zbuffers";
  version = "v0.4.0";
  src = fetchurl {
    url = "https://github.com/Strech/zbuffers/releases/download/${version}/zbuffers.wasm";
    sha256 = "sha256-gfjO+KVUeB+Viw9OOFupuwhuBsUtdaa3dZ3ditBTKCo=";
  };
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${pname}.wasm
    chmod +x $out/bin/${pname}.wasm
  '';

  meta = with lib; {
    description = "Zellij plugin for convenient switching between tabs with search capabilities";
    homepage = "https://github.com/Strech/zbuffers";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
