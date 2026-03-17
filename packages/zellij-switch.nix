{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zellij-switch";
  version = "0.2.1";

  src = fetchurl {
    url = "https://github.com/mostafaqanbaryan/zellij-switch/releases/download/${version}/zellij-switch.wasm";
    sha256 = "sha256-7yV+Qf/rczN+0d6tMJlC0UZj0S2PWBcPDNq1BFsKIq4=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${pname}.wasm
    chmod +x $out/bin/${pname}.wasm
  '';

  meta = with lib; {
    description = "A zellij plugin to switch between different programming language contexts.";
    homepage = "https://github.com/mostafaqanbaryan/zellij-switch";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
