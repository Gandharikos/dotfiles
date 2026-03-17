{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zellij-cb";
  version = "v0.1.0";
  src = fetchurl {
    url = "https://github.com/ndavd/zellij-cb/releases/download/${version}/zellij-cb.wasm";
    sha256 = "sha256-hTs7sNncMNoxLb54D+7/PGno52xDqv6tX04FbThf6dE=";
  };
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${pname}.wasm
    chmod +x $out/bin/${pname}.wasm
  '';

  meta = with lib; {
    description = "Customizable compact bar plugin for Zellij";
    homepage = "https://github.com/ndavd/zellij-cb";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
