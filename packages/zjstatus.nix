{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zjstatus";
  version = "v0.21.1";

  src = fetchurl {
    url = "https://github.com/dj95/zjstatus/releases/download/${version}/zjstatus.wasm";
    sha256 = "06mfcijmsmvb2gdzsql6w8axpaxizdc190b93s3nczy212i846fw";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${pname}.wasm
    chmod +x $out/bin/${pname}.wasm
  '';

  meta = with lib; {
    description = "zellijg plugin to show status";
    homepage = "https://github.com/dj95/zjstatus";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
