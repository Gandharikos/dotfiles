{
  lib,
  lndir,
  rime-ice,
  rime-zhwiki,
  stdenvNoCC,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "rime-ice-zhwiki";
  inherit (rime-ice) version;

  dontUnpack = true;
  nativeBuildInputs = [ lndir ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/rime-data"
    lndir -silent ${rime-ice}/share/rime-data "$out/share/rime-data"
    rm "$out/share/rime-data/rime_ice.dict.yaml"
    awk '/^[.][.][.]$/ && !added { print "  - zhwiki"; added = 1 } { print } END { if (!added) exit 1 }' \
      ${rime-ice}/share/rime-data/rime_ice.dict.yaml > "$out/share/rime-data/rime_ice.dict.yaml"
    ln -s ${rime-zhwiki}/share/rime-data/zhwiki.dict.yaml "$out/share/rime-data/zhwiki.dict.yaml"
    runHook postInstall
  '';

  meta = {
    description = "Rime Ice with the zhwiki dictionary imported";
    license = with lib.licenses; [
      gpl3Only
      fdl13Plus
      cc-by-sa-40
    ];
    platforms = lib.platforms.all;
  };
}
