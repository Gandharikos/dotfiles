{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zj-quit";
  version = "0.3.1";

  src = fetchurl {
    url = "https://github.com/cristiand391/zj-quit/releases/download/${version}/zj-quit.wasm";
    sha256 = "sha256-JSYnGGN2SLNComhMg4P814dV3TV6jRvTv9fts9oTf5Q=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${pname}.wasm
    chmod +x $out/bin/${pname}.wasm
  '';

  meta = with lib; {
    description = "A Zellij plugin that asks for confirmation before quitting.";
    homepage = "https://github.com/cristiand391/zj-quit";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
