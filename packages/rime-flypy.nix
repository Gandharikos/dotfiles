{
  fetchFromGitHub,
  lib,
  stdenvNoCC,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "rime-flypy";
  version = "10.26.1";

  src = fetchFromGitHub {
    owner = "cubercsl";
    repo = "rime-flypy";
    rev = "9ee464765e325dfd4b04926028d79d60882e653e";
    hash = "sha256-93LIHP1Ho/Jo2OOS0Dkmu+IFOJcUAFVxiKs3e5BxEK8=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/rime-data"
    cp *.schema.yaml *.dict.yaml "$out/share/rime-data/"
    cp -r flypy lua "$out/share/rime-data/"
    runHook postInstall
  '';

  passthru = {
    rimeFiles = [
      "flypy.schema.yaml"
      "flypy.dict.yaml"
      "flypydz.schema.yaml"
      "flypydz.dict.yaml"
      "flypyok.schema.yaml"
      "flypyok.dict.yaml"
      "lua/calculator_translator.lua"
      "lua/flypy_date_translator.lua"
      "lua/flypy_time_translator.lua"
    ];
    rimeDirectories = [ "flypy" ];
  };

  meta = {
    description = "Flypy shape input scheme for Rime";
    homepage = "https://github.com/cubercsl/rime-flypy";
    # The repository contains dictionaries extracted from the official package without a clear license.
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
  };
}
