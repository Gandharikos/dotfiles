{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zellij-bookmarks";
  version = "v0.4.0";
  src = fetchurl {
    url = "https://github.com/yaroslavborbat/zellij-bookmarks/releases/download/${version}/zellij-bookmarks.wasm";
    sha256 = "sha256-3xOu4/rpoyuJSyffkmlDZma2yvzuGtSgm7PKcOHPnpQ=";
  };
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${pname}.wasm
    chmod +x $out/bin/${pname}.wasm
  '';

  meta = with lib; {
    description = "Zellij plugin for creating, managing, and quickly inserting command bookmarks into the terminal.";
    homepage = "https://github.com/yaroslavborbat/zellij-bookmarks";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
