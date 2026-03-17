{
  fetchFromGitHub,
  git,
  lib,
  nodejs,
  pnpm_10,
  pnpmConfigHook,
  fetchPnpmDeps,
  stdenv,
  buildWebExtension ? false,
  ...
}:
let
  version = "v1.14.2.1";
  hash = "sha256-H1EHxz8xTCRhMFk7ep8Q+SR3O/H3wrRDYQULN5wwBis=";
  pnpmDeps = "sha256-MTvgZcWaicswKLEyyFLGWSwQBOO8uwlcGs7r7Md0QiU=";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "equicord";
  inherit version;

  src = fetchFromGitHub {
    owner = "Equicord";
    repo = "Equicord";
    tag = "${finalAttrs.version}";
    inherit hash;
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    hash = pnpmDeps;
    fetcherVersion = 2;
  };

  nativeBuildInputs = [
    git
    nodejs
    pnpm_10
    pnpmConfigHook
  ];

  env = {
    EQUICORD_REMOTE = "${finalAttrs.src.owner}/${finalAttrs.src.repo}";
    EQUICORD_HASH = "${finalAttrs.src.tag}";
  };

  buildPhase = ''
    runHook preBuild
    pnpm run ${if buildWebExtension then "buildWeb" else "build"} \
      -- --standalone --disable-updater
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cp -r dist/${lib.optionalString buildWebExtension "chromium-unpacked/"} $out
    runHook postInstall
  '';

  passthru = { };
})
