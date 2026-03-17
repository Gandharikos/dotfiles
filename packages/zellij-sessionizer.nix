{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zellij-sessionizer";
  version = "v0.4.3";

  src = fetchurl {
    url = "https://github.com/laperlej/zellij-sessionizer/releases/download/${version}/zellij-sessionizer.wasm";
    sha256 = "sha256-AGuWbuRX7Yi9tPdZTzDKULXh3XLUs4navuieCimUgzQ=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${pname}.wasm
    chmod +x $out/bin/${pname}.wasm
  '';

  meta = with lib; {
    description = "A session manager for Zellij";
    homepage = "https://github.com/laperlej/zellij-sessionizer";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
