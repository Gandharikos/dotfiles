{
  fetchurl,
  lib,
  stdenvNoCC,
  ...
}:
let
  grammar = fetchurl {
    url = "https://raw.githubusercontent.com/lotem/rime-octagram-data/8ceef1b42eb77e86501382a52e85c309c0f2f04c/grammar.yaml";
    hash = "sha256-pYzp7x3IEGY07TBVZagywG3eycAXllAbGkra63cmQSk=";
  };
  hansModel = fetchurl {
    url = "https://raw.githubusercontent.com/lotem/rime-octagram-data/9c482c6660fa9e3268bd1d1a9341ef26aa90f94d/zh-hans-t-essay-bgw.gram";
    hash = "sha256-Ebvuu4TjIdwmF9X+TBs8UZRXA+13mhLhK4sCcOG67Hk=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "rime-octagram-data";
  version = "0-unstable-2024-12-23";

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/rime-data"
    ln -s ${grammar} "$out/share/rime-data/grammar.yaml"
    ln -s ${hansModel} "$out/share/rime-data/zh-hans-t-essay-bgw.gram"
    runHook postInstall
  '';

  meta = {
    description = "Octagram configuration and simplified Chinese language model for Rime";
    homepage = "https://github.com/lotem/rime-octagram-data";
    license = lib.licenses.lgpl3Only;
    platforms = lib.platforms.all;
  };
}
