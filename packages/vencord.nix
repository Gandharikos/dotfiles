{
  fetchFromGitHub,
  gitMinimal,
  lib,
  nodejs_22,
  stdenv,
  buildWebExtension ? false,
  unstable ? false,
  pnpm_10,
  pnpmConfigHook,
  fetchPnpmDeps,
  ...
}:
let
  stableVersion = "1.14.2";
  stableHash = "sha256-1459x8G0++jH6NO5n4B5LVjDFjAFkLKFAQygVdqgOAk=";
  stablePnpmDeps = "sha256-K9rjPsODn56kM2k5KZHxY99n8fKvWbRbxuxFpYVXYks=";

  unstableVersion = "1.14.2-unstable-2026-02-10";
  unstableRev = "f9c404c229af828b362086ae954252647c80b208";
  unstableHash = "sha256-KYOdA41BCP3gnwM/yqmgh/qV+zKaR12c04k52RG6q6g=";
  unstablePnpmDeps = "sha256-K9rjPsODn56kM2k5KZHxY99n8fKvWbRbxuxFpYVXYks=";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "vencord" + lib.optionalString unstable "-unstable";
  version = if unstable then unstableVersion else stableVersion;

  src = fetchFromGitHub {
    owner = "Vendicated";
    repo = "Vencord";
    rev = if unstable then unstableRev else "v${finalAttrs.version}";
    hash = if unstable then unstableHash else stableHash;
  };

  patches = [ ./fix-deps.patch ];

  postPatch = ''
    substituteInPlace packages/vencord-types/package.json \
      --replace-fail '"@types/react": "18.3.1"' '"@types/react": "19.0.12"'
  '';

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs)
      pname
      src
      patches
      postPatch
      ;
    pnpm = pnpm_10;
    hash = if unstable then unstablePnpmDeps else stablePnpmDeps;
    fetcherVersion = 2;
  };

  nativeBuildInputs = [
    gitMinimal
    nodejs_22
    pnpm_10
    pnpmConfigHook
  ];

  env = {
    VENCORD_REMOTE = "${finalAttrs.src.owner}/${finalAttrs.src.repo}";
    VENCORD_HASH = "${finalAttrs.version}";
  };

  buildPhase = ''
    runHook preBuild
    pnpm run ${if buildWebExtension then "buildWeb" else "build"} \
      -- --standalone --disable-updater
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cp -r dist/${lib.optionalString buildWebExtension "chromium-unpacked/"} "$out"
    cp package.json "$out"
    runHook postInstall
  '';

  passthru = { };
})
