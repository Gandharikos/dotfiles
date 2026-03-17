{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zellij-choose-tree";
  version = "v0.4.2";
  src = fetchurl {
    url = "https://github.com/laperlej/zellij-choose-tree/releases/download/${version}/zellij-choose-tree.wasm";
    sha256 = "OGHLzCM9wg0CLm5SSr3bmElcciBIqamalQjgkTuzAeg=";
  };
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${pname}.wasm
    chmod +x $out/bin/${pname}.wasm
  '';

  meta = with lib; {
    description = "zellij-choose-tree is a plugin for zellij that allows users to quickly switch between sessions.";
    homepage = "https://github.com/laperlej/zellij-choose-tree";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
