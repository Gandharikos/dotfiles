{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zj-status-bar";
  version = "0.3.0";

  src = fetchurl {
    url = "https://github.com/cristiand391/zj-status-bar/releases/download/${version}/zj-status-bar.wasm";
    sha256 = "sha256-seiWCtsrkFnDwXrXrAOE6y9EUWzpnb8qgHqRDdMKCeg=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${pname}.wasm
    chmod +x $out/bin/${pname}.wasm
  '';

  meta = with lib; {
    description = "A status bar for Zellij";
    homepage = "https://github.com/cristiand391/zj-status-bar";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
