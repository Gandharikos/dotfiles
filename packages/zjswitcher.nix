{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zjswitcher";
  version = "v0.2.1";

  src = fetchurl {
    url = "https://github.com/WingsZeng/zjswitcher/releases/download/${version}/zjswitcher.wasm";
    sha256 = "sha256-VivWbv7wGW/a6HetoxaMk8EbNrdKS2KJEQhlUv0gdq4=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${pname}.wasm
    chmod +x $out/bin/${pname}.wasm
  '';

  meta = with lib; {
    description = "A zellij plugin to switch sessions, tabs, panes.";
    homepage = "https://github.com/WingsZeng/zjswitcher";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
