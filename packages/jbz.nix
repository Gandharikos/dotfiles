{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "jbz";
  version = "v0.39.0";

  src = fetchurl {
    url = "https://github.com/nim65s/jbz/releases/download/${version}/jbz.wasm";
    sha256 = "sha256-YqTsOWlUBZy7CoKwdrEAyx1xHjFLdbJughTflK+qPBM=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${pname}.wasm
    chmod +x $out/bin/${pname}.wasm
  '';

  meta = with lib; {
    description = "A Zellij plugin to display your just commands wrapped in bacon";
    homepage = "https://github.com/nim65s/jbz";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
