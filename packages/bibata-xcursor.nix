{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  clickgen,
  resvg,
  cursorThemeName ? "Bibata-Themed",
  baseColor ? "#000000",
  outlineColor ? "#FFFFFF",
  watchBackgroundColor ? "#000000",
  ...
}:
stdenvNoCC.mkDerivation rec {
  pname = "bibata-cursor-themed";
  version = "2.0.7";

  src = fetchFromGitHub {
    owner = "ful1e5";
    repo = "Bibata_Cursor";
    rev = "v${version}";
    hash = "sha256-kIKidw1vditpuxO1gVuZeUPdWBzkiksO/q2R/+DUdEc=";
  };

  nativeBuildInputs = [
    clickgen
    resvg
  ];

  buildPhase = ''
    runHook preBuild

    shopt -s globstar

    tmpdir="$(mktemp -d)"
    mkdir -p "$tmpdir/in" "$tmpdir/out"

    cp ./svg/modern/**/*.svg "$tmpdir/in"

    sed -i \
      -e "s/#00FF00/${baseColor}/g" \
      -e "s/#0000FF/${outlineColor}/g" \
      -e "s/#FF0000/${watchBackgroundColor}/g" \
      "$tmpdir/in"/*.svg

    for f in "$tmpdir/in"/*.svg; do
      base=$(basename "$f" .svg)
      resvg "$f" "$tmpdir/out/$base.png"
    done

    ctgen configs/normal/x.build.toml \
      -p x11 \
      -d "$tmpdir/out" \
      -n '${cursorThemeName}' \
      -c 'Bibata XCursor themed with Nix'

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -dm 0755 "$out/share/icons"
    cp -rf themes/* "$out/share/icons/"

    runHook postInstall
  '';

  meta = {
    description = "Material Based Cursor Theme";
    homepage = "https://github.com/ful1e5/Bibata_Cursor";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
