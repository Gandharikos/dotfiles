{
  lib,
  stdenvNoCC,
  fetchurl,
  darwin,
  testers,
  ...
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "krd";
  version = "0.3.0";

  src = fetchurl {
    url = "https://github.com/zzjcool/krd/releases/download/v${finalAttrs.version}/krd-v${finalAttrs.version}-macos-universal.tar.gz";
    hash = "sha256-tkYdyAisJt/Ikj0qW9lHGW/JN7yTD9Kaf64tAttClxo=";
  };

  nativeBuildInputs = [
    darwin.cctools
    darwin.sigtool
  ];
  dontConfigure = true;
  dontBuild = true;
  # Keep the universal Mach-O intact after signing; it uses Apple's system frameworks.
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 krd "$out/bin/krd"
    install -Dm644 LICENSE "$out/share/licenses/krd/LICENSE"
    codesign --force --sign - --identifier com.kkrt.macdesk "$out/bin/krd"

    runHook postInstall
  '';

  passthru.tests.version = testers.testVersion { package = finalAttrs.finalPackage; };

  meta = {
    description = "Display and control a macOS 14+ desktop in a Kitty graphics terminal over SSH";
    homepage = "https://github.com/zzjcool/krd";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = lib.platforms.darwin;
    mainProgram = "krd";
  };
})
