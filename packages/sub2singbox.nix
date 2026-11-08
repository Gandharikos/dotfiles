{
  lib,
  fetchFromGitHub,
  stdenv,
  makeWrapper,
  python3,
  ...
}:
let
  pythonEnv = python3.withPackages (
    p: with p; [
      flask
      requests
      scp
      paramiko
      chardet
      cryptography
      pyaml
      ruamel-yaml
    ]
  );
in
stdenv.mkDerivation {
  pname = "sing-box-subscribe";
  version = "2.8.0-unstable-2025-03-15";

  src = fetchFromGitHub {
    owner = "Toperlock";
    repo = "sing-box-subscribe";
    rev = "f7208af375e10c69a077934612860797a3c26cbd";
    hash = "sha256-PJCgbSvIQfMex0ScTEJXlASFcTpkwroH8WBqYcuw+A4=";
  };

  nativeBuildInputs = [
    pythonEnv
    makeWrapper
  ];

  # Clash passwords are data, not URI syntax; preserve reserved characters on both sides.
  postPatch = ''
    substituteInPlace parsers/clash2base64.py \
      --replace-fail $'trojan_info = {\n            "password": share_link[\'password\'],' \
        $'trojan_info = {\n            "password": quote(share_link[\'password\'], safe=""),'
    substituteInPlace parsers/trojan.py \
      --replace-fail "'password': _netloc[0]," "'password': unquote(_netloc[0]),"
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,opt}
    cp -r * $out/opt/

    makeWrapper ${lib.getExe' pythonEnv "python"} $out/bin/sub2singbox \
      --run "cd $out/opt" \
      --add-flags "$out/opt/main.py"

    runHook postInstall
  '';

  meta = {
    description = "Convert subscribe to sing-box config.json";
    homepage = "https://github.com/Toperlock/sing-box-subscribe";
    mainProgram = "sub2singbox";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ zendo ];
  };
}
