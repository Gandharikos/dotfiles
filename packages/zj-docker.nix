{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zj-docker";
  version = "v0.4.0";

  src = fetchurl {
    url = "https://github.com/dj95/zj-docker/releases/download/${version}/zj-docker.wasm";
    sha256 = "sha256-vmVSbgFCDo0iOcpkA8LZY2/yGt5B2PQKwghCRjmJhmQ=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${pname}.wasm
    chmod +x $out/bin/${pname}.wasm
  '';

  meta = with lib; {
    description = "A zellij plugin for docker";
    homepage = "https://github.com/dj95/zj-docker";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
