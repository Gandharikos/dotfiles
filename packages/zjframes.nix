{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zjframes";
  version = "v0.21.1";

  src = fetchurl {
    url = "https://github.com/dj95/zjstatus/releases/download/${version}/zjframes.wasm";
    sha256 = "05nizb96llh80srgy38lwciv371y3qr1rd2q4iw5zkgvqd0lxnd0";
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
