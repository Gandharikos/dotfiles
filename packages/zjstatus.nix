{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zjstatus";
  version = "v0.22.0";

  src = fetchurl {
    url = "https://github.com/dj95/zjstatus/releases/download/${version}/zjstatus.wasm";
    sha256 = "sha256-TeQm0gscv4YScuknrutbSdksF/Diu50XP4W/fwFU3VM=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${pname}.wasm
    chmod +x $out/bin/${pname}.wasm
  '';

  meta = with lib; {
    description = "zellijg plugin to show status";
    homepage = "https://github.com/dj95/zjstatus";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
