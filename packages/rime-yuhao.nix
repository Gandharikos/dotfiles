{
  fetchurl,
  lib,
  stdenvNoCC,
  unzip,
  ...
}:
let
  version = "3.11.0";
  releaseUrl = "https://github.com/forfudan/yuhao-ime-release/releases/download/v${version}";
  star = fetchurl {
    url = "${releaseUrl}/xingchen_v${version}.zip";
    hash = "sha256-o9Ht+Va0ccr0N2hjuN+3F6biXFUdsrfxh/RF8c70t6U=";
  };
  sunMoon = fetchurl {
    url = "${releaseUrl}/riyue_daming_v${version}.zip";
    hash = "sha256-CqITr+7bU+xxYXscAla4MbSV3AZYZhAx9GTDBwjyCsY=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "rime-yuhao";
  inherit version;

  dontUnpack = true;
  nativeBuildInputs = [ unzip ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/rime-data" "$TMPDIR/star" "$TMPDIR/sunmoon"
    # The archives contain legacy filenames outside schema/ that fetchzip cannot decode.
    unzip -qq ${star} 'schema/*' -d "$TMPDIR/star"
    unzip -qq ${sunMoon} 'schema/*' -d "$TMPDIR/sunmoon"
    cp -r "$TMPDIR/star/schema/." "$out/share/rime-data/"
    cp -r "$TMPDIR/sunmoon/schema/." "$out/share/rime-data/"
    rm "$out/share/rime-data/default.custom.yaml"
    runHook postInstall
  '';

  passthru = {
    rimeFiles = [
      "yuhao.essay.txt"
      "yuhao_pinyin.schema.yaml"
      "yuhao_pinyin.dict.yaml"
      "yustar.schema.yaml"
      "yustar.dict.yaml"
      "yustar_chaifen.schema.yaml"
      "yustar_chaifen.dict.yaml"
      "yuming.schema.yaml"
      "yuming.dict.yaml"
      "yuming_chaifen.schema.yaml"
      "yuming_chaifen.dict.yaml"
      "yuming_chaifen_tw.schema.yaml"
      "yuming_chaifen_tw.dict.yaml"
    ];
    rimeDirectories = [
      "yuhao"
      "lua/yuhao"
    ];
  };

  meta = {
    description = "Official Yuhao Star and Sun-Moon Rime input schemes";
    homepage = "https://shurufa.app";
    license = lib.licenses.cc-by-nc-nd-40;
    platforms = lib.platforms.all;
  };
}
