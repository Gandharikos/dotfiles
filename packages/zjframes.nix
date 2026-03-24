{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zjframes";
  version = "v0.22.0";

  src = fetchurl {
    url = "https://github.com/dj95/zjstatus/releases/download/${version}/zjframes.wasm";
    sha256 = "sha256-lg5RzEbuM3hravlN1DOWVnoX48G2iQSrgawRrL89r/A=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${pname}.wasm
    chmod +x $out/bin/${pname}.wasm
  '';

  meta = with lib; {
    description = "zellijg plugin to show frames status";
    homepage = "https://github.com/dj95/zjstatus";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
