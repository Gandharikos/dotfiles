{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zellij-workspace";
  version = "v0.3.0";

  src = fetchurl {
    url = "https://github.com/vdbulcke/zellij-workspace/releases/download/${version}/zellij-workspace.wasm";
    sha256 = "sha256-PR8Epa9JfQUHKg+jBF/9Rs3TDzM/9IYXcdm+kJsJa3M=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${pname}.wasm
    chmod +x $out/bin/${pname}.wasm
  '';

  meta = with lib; {
    description = "A Zellij plugin to easily navigate and create workspaces";
    homepage = "https://github.com/vdbulcke/zellij-workspace";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
