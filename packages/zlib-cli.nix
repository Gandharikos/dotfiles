{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}:
buildGoModule rec {
  pname = "zlib-cli";
  version = "0.0.12";

  src = fetchFromGitHub {
    owner = "heartleo";
    repo = "zlib";
    tag = "v${version}";
    hash = "sha256-IQ/KQSKlG4XFbLsO85GznccF+Qp2PPaFoL6mwARBxZQ=";
  };

  vendorHash = "sha256-qXzhQI8LCMnVi5Mu1a8QHPhSyzHeqxQEN0wfb0tlTms=";

  subPackages = [ "cmd/zlib" ];
  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/heartleo/zlib/internal/zlib.Version=v${version}"
  ];

  meta = {
    description = "Command-line client for Z-Library";
    homepage = "https://github.com/heartleo/zlib";
    license = lib.licenses.mit;
    mainProgram = "zlib";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
