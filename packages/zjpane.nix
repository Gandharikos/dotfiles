{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zjpane";
  version = "v0.2.0";

  src = fetchurl {
    url = "https://github.com/FuriouZz/zjpane/releases/download/${version}/zjpane.wasm";
    sha256 = "sha256-N2u0nPY//EpnJ6YoFGgoS7taL3S/SxfrE2qKfgywqt4=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${pname}.wasm
    chmod +x $out/bin/${pname}.wasm
  '';

  meta = with lib; {
    description = "Zellij plugin to navigate between panes and create new ones";
    homepage = "https://github.com/FuriouZz/zjpane";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
