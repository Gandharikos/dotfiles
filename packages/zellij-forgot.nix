{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zellij-forgot";
  version = "0.4.2";

  src = fetchurl {
    url = "https://github.com/karimould/zellij-forgot/releases/download/${version}/zellij_forgot.wasm";
    sha256 = "sha256-MRlBRVGdvcEoaFtFb5cDdDePoZ/J2nQvvkoyG6zkSds=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${pname}.wasm
    chmod +x $out/bin/${pname}.wasm
  '';

  meta = with lib; {
    description = "A zellij plugin that allows you to close tabs without closing the session";
    homepage = "https://github.com/karimould/zellij-forgot";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
