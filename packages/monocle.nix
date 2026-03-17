{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "monocle";
  version = "v0.100.2";

  src = fetchurl {
    url = "https://github.com/imsnif/monocle/releases/download/${version}/monocle.wasm";
    sha256 = "sha256-TLfizJEtl1tOdVyT5E5/DeYu+SQKCaibc1SQz0cTeSw=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${pname}.wasm
    chmod +x $out/bin/${pname}.wasm
  '';

  meta = with lib; {
    description = "A Zellij plugin to fuzzy find file names and contents in style";
    homepage = "https://github.com/imsnif/monocle";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
